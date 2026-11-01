import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/validators.dart';
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
    on<OtpRequested>(_onOtpRequested);
    on<OtpVerified>(_onOtpVerified);
    on<GuestRequested>(_onGuestRequested);
    on<AccountSubmitted>(_onAccountSubmitted);
    on<AuthReset>(_onAuthReset);
  }

  final AuthRepository _authRepository;

  /// Validates the mobile, then requests an OTP. Invalid numbers surface an
  /// inline error and no code is sent.
  Future<void> _onOtpRequested(
    OtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!Validators.isValidIndianMobile(event.mobile)) {
      emit(state.copyWith(
        phase: AuthPhase.error,
        errorMessage: 'Enter a valid 10-digit mobile',
      ));
      return;
    }

    emit(state.copyWith(phase: AuthPhase.sendingOtp, clearError: true));
    try {
      final session = await _authRepository.sendOtp(mobile: event.mobile);
      emit(state.copyWith(
        phase: AuthPhase.otpSent,
        session: session,
        clearError: true,
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        phase: AuthPhase.error,
        errorMessage: failure.message ?? 'Could not send the OTP.',
      ));
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
      emit(state.copyWith(
        phase: AuthPhase.authenticated,
        user: user,
        clearError: true,
      ));
    } on InvalidOtpFailure {
      emit(state.copyWith(
        phase: AuthPhase.error,
        errorMessage: 'Incorrect code',
      ));
    } on Failure catch (failure) {
      emit(state.copyWith(
        phase: AuthPhase.error,
        errorMessage: failure.message ?? 'Could not verify the code.',
      ));
    }
  }

  /// Starts a guest session; the resulting user has `isGuest == true`.
  Future<void> _onGuestRequested(
    GuestRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _authRepository.continueAsGuest();
    emit(state.copyWith(
      phase: AuthPhase.authenticated,
      user: user,
      clearError: true,
    ));
  }

  /// Creates an account from the submitted sign-up draft.
  Future<void> _onAccountSubmitted(
    AccountSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(phase: AuthPhase.creating, clearError: true));
    final user = await _authRepository.createAccount(event.draft);
    emit(state.copyWith(
      phase: AuthPhase.authenticated,
      user: user,
      clearError: true,
    ));
  }

  /// Resets the flow back to its initial idle state.
  void _onAuthReset(AuthReset event, Emitter<AuthState> emit) {
    emit(const AuthState.idle());
  }
}
