import '../entities/auth_user.dart';
import '../entities/otp_session.dart';

/// Contract for authentication: OTP sign-in, account creation, and guest
/// sessions. Implementations may throw an [InvalidOtpFailure] from
/// [verifyOtp] when the code is wrong or expired.
abstract interface class AuthRepository {
  /// Requests an OTP for [mobile] (+91). Returns a session (mock: code "0000").
  Future<OtpSession> sendOtp({required String mobile});

  /// Verifies [code] against [sessionId]. Returns the signed-in user on
  /// success; throws an `InvalidOtpFailure` on an incorrect or expired code.
  Future<AuthUser> verifyOtp({required String sessionId, required String code});

  /// Whether a profile record already exists in the backing store for the
  /// user identified by [uid]. Used after OTP verification to decide whether
  /// to send the user to Home (existing account) or to the Sign up form (new
  /// account that must be registered first).
  Future<bool> isRegistered(String uid);

  /// Loads the stored profile for [uid], or `null` when no record exists.
  Future<AuthUser?> loadProfile(String uid);

  /// Creates an account from the sign-up form and persists the profile to the
  /// backing store. Must be called while the user is already signed in (via
  /// OTP), so the record is keyed by the authenticated uid.
  Future<AuthUser> createAccount(AuthUser draftUser);

  /// Starts a guest session (no credentials).
  Future<AuthUser> continueAsGuest();

  /// Currently signed-in user, or `null` if none.
  AuthUser? get currentUser;
}
