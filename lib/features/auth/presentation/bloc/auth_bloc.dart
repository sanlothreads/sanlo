import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// Drives the authentication flow: OTP send/verify, guest sign-in, and account
/// creation.
///
/// Holds a single [AuthState] whose [AuthPhase] captures where the user is in
/// the flow. Delegates all I/O to the injected [AuthRepository].
///
/// Validates Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.9, 1.11.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState.idle()) {
    on<AppStarted>(_onAppStarted);
    on<OtpRequested>(_onOtpRequested);
    on<OtpVerified>(_onOtpVerified);
    on<GuestRequested>(_onGuestRequested);
    on<AccountSubmitted>(_onAccountSubmitted);
    on<ProfileUpdated>(_onProfileUpdated);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthReset>(_onAuthReset);
  }

  final AuthRepository _authRepository;

  /// Restores any persisted session at startup. Firebase keeps the signed-in
  /// user across app restarts, so if one exists (and is not a guest) we load
  /// their stored profile and move straight to [AuthPhase.authenticated];
  /// otherwise the flow stays idle and the app shows Sign in.
  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final AuthUser? current = _authRepository.currentUser;
    if (current == null || current.isGuest || current.id == null) {
      return; // no restorable real session; remain idle
    }

    emit(state.copyWith(phase: AuthPhase.restoring, clearError: true));
    try {
      final AuthUser profile =
          await _authRepository.loadProfile(current.id!) ?? current;
      emit(
        state.copyWith(
          phase: AuthPhase.authenticated,
          user: profile,
          clearError: true,
        ),
      );
    } on Failure {
      // Could not reach the profile store; keep the signed-in identity so the
      // app still treats the user as authenticated rather than bouncing them
      // back to Sign in.
      emit(
        state.copyWith(
          phase: AuthPhase.authenticated,
          user: current,
          clearError: true,
        ),
      );
    }
  }

  /// Validates the mobile, then requests an OTP. Invalid numbers surface an
  /// inline error and no code is sent.
  Future<void> _onOtpRequested(
    OtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!Validators.isValidIndianMobile(event.mobile)) {
      emit(
        state.copyWith(
          phase: AuthPhase.error,
          errorMessage: 'Enter a valid 10-digit mobile',
        ),
      );
      return;
    }

    emit(state.copyWith(phase: AuthPhase.sendingOtp, clearError: true));
    try {
      final session = await _authRepository.sendOtp(mobile: event.mobile);
      emit(
        state.copyWith(
          phase: AuthPhase.otpSent,
          session: session,
          clearError: true,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          phase: AuthPhase.error,
          errorMessage: failure.message ?? 'Could not send the OTP.',
        ),
      );
    }
  }

  /// Verifies the entered code against the active session. Returns early if no
  /// OTP has been sent yet; maps an [InvalidOtpFailure] to an inline error.
  Future<void> _onOtpVerified(
    OtpVerified event,
    Emitter<AuthState> emit,
  ) async {
    final session = state.session;
    if (session == null) return; // cannot verify before sending

    emit(state.copyWith(phase: AuthPhase.verifying, clearError: true));
    try {
      final user = await _authRepository.verifyOtp(
        sessionId: session.sessionId,
        code: event.code,
      );

      // After a successful OTP sign-in, decide where the user goes: an existing
      // profile in the backing store means they are registered (-> Home), a
      // missing one means they must complete the Sign up form first.
      final String? uid = user.id;
      final bool registered =
          uid != null && await _authRepository.isRegistered(uid);

      if (registered) {
        // Load the stored profile so Home/Profile have the full details.
        // `uid` is non-null here (registered implies it), so the lookup is safe.
        final AuthUser profile = await _authRepository.loadProfile(uid) ?? user;
        emit(
          state.copyWith(
            phase: AuthPhase.authenticated,
            user: profile,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            phase: AuthPhase.needsRegistration,
            user: user,
            clearError: true,
          ),
        );
      }
    } on InvalidOtpFailure {
      emit(
        state.copyWith(phase: AuthPhase.error, errorMessage: 'Incorrect code'),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          phase: AuthPhase.error,
          errorMessage: failure.message ?? 'Could not verify the code.',
        ),
      );
    }
  }

  /// Starts a guest session; the resulting user has `isGuest == true`. Any
  /// failure still lands the user in a local guest session so "Continue as
  /// guest" / "Skip" always proceeds to Home rather than silently doing
  /// nothing.
  Future<void> _onGuestRequested(
    GuestRequested event,
    Emitter<AuthState> emit,
  ) async {
    AuthUser user;
    try {
      user = await _authRepository.continueAsGuest();
    } catch (_) {
      user = const AuthUser.guest();
    }
    emit(
      state.copyWith(
        phase: AuthPhase.authenticated,
        user: user,
        clearError: true,
      ),
    );
  }

  /// Creates an account from the submitted sign-up draft and persists it to the
  /// backing store. On success the user is authenticated (-> Home); a failure
  /// surfaces an inline error and keeps the form usable.
  Future<void> _onAccountSubmitted(
    AccountSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(phase: AuthPhase.creating, clearError: true));
    try {
      final user = await _authRepository.createAccount(event.draft);
      emit(
        state.copyWith(
          phase: AuthPhase.authenticated,
          user: user,
          clearError: true,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          phase: AuthPhase.error,
          errorMessage: failure.message ?? 'Could not create your account.',
        ),
      );
    }
  }

  /// Persists edited profile fields and refreshes [AuthState.user] on success.
  /// The mobile/uid are pinned by the repository, so only the editable fields
  /// change. A failure surfaces an inline error and keeps the user signed in.
  Future<void> _onProfileUpdated(
    ProfileUpdated event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(phase: AuthPhase.savingProfile, clearError: true));
    try {
      final AuthUser saved = await _authRepository.updateProfile(event.user);
      emit(
        state.copyWith(
          phase: AuthPhase.authenticated,
          user: saved,
          clearError: true,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          phase: AuthPhase.error,
          errorMessage: failure.message ?? 'Could not save your changes.',
        ),
      );
    }
  }

  /// Signs the current user out, clears the session/user, and moves to
  /// [AuthPhase.loggedOut] so the UI can route back to Sign in.
  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(const AuthState(phase: AuthPhase.loggedOut));
  }

  /// Resets the flow back to its initial idle state.
  void _onAuthReset(AuthReset event, Emitter<AuthState> emit) {
    emit(const AuthState.idle());
  }
}
