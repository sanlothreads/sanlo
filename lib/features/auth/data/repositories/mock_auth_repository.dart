import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/otp_session.dart';
import '../../domain/repositories/auth_repository.dart';

/// In-memory mock implementation of [AuthRepository].
///
/// Accepts any mobile number, uses the fixed OTP code `0000`, and never fails
/// account creation. Intended for local development and testing before a real
/// backend is wired in.
class MockAuthRepository implements AuthRepository {
  /// The fixed OTP code accepted by [verifyOtp] in the mock.
  static const String _mockOtpCode = '0000';

  /// How long an OTP session remains valid.
  static const Duration _sessionTtl = Duration(minutes: 5);

  /// Tracks the mobile number associated with each active session id so
  /// [verifyOtp] can recover the mobile after [sendOtp].
  final Map<String, String> _sessionMobiles = {};

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<OtpSession> sendOtp({required String mobile}) async {
    final now = DateTime.now();
    final sessionId = 'mock-session-$mobile-${now.microsecondsSinceEpoch}';
    _sessionMobiles[sessionId] = mobile;
    return OtpSession(
      sessionId: sessionId,
      mobile: mobile,
      expiresAt: now.add(_sessionTtl),
    );
  }

  @override
  Future<AuthUser> verifyOtp({
    required String sessionId,
    required String code,
  }) async {
    if (code != _mockOtpCode) {
      throw const InvalidOtpFailure('Incorrect OTP code.');
    }

    final mobile = _sessionMobiles[sessionId];
    final user = AuthUser(
      id: 'mock-user-${DateTime.now().microsecondsSinceEpoch}',
      isGuest: false,
      mobile: mobile,
    );
    _currentUser = user;
    return user;
  }

  /// In-memory store of registered profiles, keyed by user id. Populated by
  /// [createAccount] so [isRegistered] / [loadProfile] mirror the Firebase
  /// behaviour without a backing database.
  final Map<String, AuthUser> _profiles = {};

  @override
  Future<bool> isRegistered(String uid) async => _profiles.containsKey(uid);

  @override
  Future<AuthUser?> loadProfile(String uid) async => _profiles[uid];

  @override
  Future<AuthUser> createAccount(AuthUser draftUser) async {
    // Prefer the signed-in user's id so a profile created right after OTP
    // verification is keyed the same way [isRegistered] later looks it up.
    final String id =
        _currentUser?.id ??
        draftUser.id ??
        'mock-user-${DateTime.now().microsecondsSinceEpoch}';
    final user = draftUser.copyWith(id: id, isGuest: false);
    _profiles[id] = user;
    _currentUser = user;
    return user;
  }

  @override
  Future<AuthUser> updateProfile(AuthUser user) async {
    // Pin uid + mobile to the current identity, then store the edit.
    final AuthUser toSave = user.copyWith(
      id: _currentUser?.id ?? user.id,
      isGuest: false,
      mobile: _currentUser?.mobile ?? user.mobile,
    );
    final String? id = toSave.id;
    if (id != null) _profiles[id] = toSave;
    _currentUser = toSave;
    return toSave;
  }

  @override
  Future<AuthUser> continueAsGuest() async {
    const user = AuthUser.guest();
    _currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}
