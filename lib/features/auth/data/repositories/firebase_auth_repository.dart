import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/otp_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_user_model.dart';

/// Firebase-backed implementation of [AuthRepository] using phone-number OTP
/// sign-in ([FirebaseAuth.verifyPhoneNumber] / [signInWithCredential]).
///
/// Firebase's phone flow is callback-based, so this class bridges it onto the
/// app's session model:
///
///  * [sendOtp] calls [FirebaseAuth.verifyPhoneNumber] and completes once
///    Firebase returns a `verificationId` (via the `codeSent` callback). That
///    id becomes the [OtpSession.sessionId], and is cached so [verifyOtp] can
///    recover it.
///  * [verifyOtp] rebuilds a [PhoneAuthCredential] from the cached
///    verification id plus the user-entered code, signs in, and maps the
///    resulting [User] to an [AuthUser].
///
/// On an invalid/expired code Firebase throws a [FirebaseAuthException]
/// (`invalid-verification-code` / `session-expired`), which is translated to
/// the domain-level [InvalidOtpFailure] the presentation layer already handles.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseDatabase? database,
  }) : _injectedAuth = firebaseAuth,
       _injectedDb = database;

  /// An explicitly injected instance (used in tests); when null we fall back to
  /// [FirebaseAuth.instance], resolved lazily so merely constructing this
  /// repository does not require Firebase to be initialised yet.
  final FirebaseAuth? _injectedAuth;

  /// Optional injected Realtime Database (used in tests); null falls back to
  /// [FirebaseDatabase.instance], resolved lazily for the same reason.
  final FirebaseDatabase? _injectedDb;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  FirebaseDatabase get _db => _injectedDb ?? FirebaseDatabase.instance;

  /// Realtime Database reference for a user's profile record: `users/<uid>`.
  DatabaseReference _userRef(String uid) => _db.ref('users/$uid');

  /// How long Firebase waits for automatic SMS retrieval / resend window.
  static const Duration _codeTimeout = Duration(seconds: 60);

  /// Maps a Firebase `verificationId` (our session id) to the phone number it
  /// was sent to, so [verifyOtp] can populate [AuthUser.mobile].
  final Map<String, String> _sessionMobiles = {};

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  /// Formats a 10-digit Indian local number into E.164 (`+91XXXXXXXXXX`).
  ///
  /// Accepts input that already carries a `+91`/`91` prefix and normalises it,
  /// so callers may pass either the raw 10-digit part or a prefixed string.
  String _toE164(String mobile) {
    var digits = mobile.replaceAll(RegExp(r'[\s()\-]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('91') && digits.length > 10) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length > 10) {
      digits = digits.substring(1);
    }
    return '+91$digits';
  }

  @override
  Future<OtpSession> sendOtp({required String mobile}) async {
    final phoneNumber = _toE164(mobile);
    final completer = Completer<OtpSession>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: _codeTimeout,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(
              AuthFailure(e.message ?? 'Could not send the verification code.'),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _sessionMobiles[verificationId] = phoneNumber;
          if (!completer.isCompleted) {
            completer.complete(
              OtpSession(
                sessionId: verificationId,
                mobile: phoneNumber,
                expiresAt: DateTime.now().add(_codeTimeout),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Keep the latest verification id so a late-entered code still works.
          _sessionMobiles[verificationId] = phoneNumber;
          if (!completer.isCompleted) {
            completer.complete(
              OtpSession(
                sessionId: verificationId,
                mobile: phoneNumber,
                expiresAt: DateTime.now().add(_codeTimeout),
              ),
            );
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(
          AuthFailure(e.message ?? 'Could not send the verification code.'),
        );
      }
    } catch (e) {
      // Surface any other failure to the caller instead of hanging the flow.
      if (!completer.isCompleted) {
        completer.completeError(AuthFailure(e.toString()));
      }
    }
    return completer.future;
  }

  @override
  Future<AuthUser> verifyOtp({
    required String sessionId,
    required String code,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: sessionId,
      smsCode: code,
    );

    try {
      final result = await _auth.signInWithCredential(credential);
      final user = _mapUser(result.user);
      if (user == null) {
        throw const AuthFailure('Sign-in failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
        case 'session-expired':
        case 'invalid-verification-id':
          throw const InvalidOtpFailure('Incorrect or expired OTP code.');
        default:
          throw AuthFailure(e.message ?? 'Could not verify the code.');
      }
    }
  }

  @override
  Future<bool> isRegistered(String uid) async {
    try {
      final snapshot = await _userRef(uid).get();
      return snapshot.exists;
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Could not check your account.');
    }
  }

  @override
  Future<AuthUser?> loadProfile(String uid) async {
    try {
      final snapshot = await _userRef(uid).get();
      if (!snapshot.exists || snapshot.value == null) return null;
      final map = Map<String, dynamic>.from(snapshot.value as Map);
      return AuthUserModel.fromJson(map).toEntity();
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Could not load your account.');
    }
  }

  @override
  Future<AuthUser> createAccount(AuthUser draftUser) async {
    // Account creation flows through phone sign-in: the user is already signed
    // in via OTP, so we key the profile record by the authenticated uid and
    // merge the signed-in identity (uid + verified phone) with the draft.
    final current = _auth.currentUser;
    if (current == null) {
      throw const AuthFailure('You must verify your mobile before signing up.');
    }

    final user = draftUser.copyWith(
      id: current.uid,
      isGuest: false,
      mobile: current.phoneNumber ?? draftUser.mobile,
    );

    try {
      final data = AuthUserModel.fromEntity(user).toJson()
        ..['createdAt'] = ServerValue.timestamp;
      await _userRef(current.uid).set(data);
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Could not save your account.');
    }

    return user;
  }

  @override
  Future<AuthUser> updateProfile(AuthUser user) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw const AuthFailure('You must be signed in to edit your profile.');
    }

    // Keep the uid and verified mobile pinned to the signed-in identity so
    // editing can never change them.
    final AuthUser toSave = user.copyWith(
      id: current.uid,
      isGuest: false,
      mobile: current.phoneNumber ?? user.mobile,
    );

    try {
      // `update` merges the editable fields, preserving `createdAt` and any
      // other keys already stored under the user's node.
      final data = AuthUserModel.fromEntity(toSave).toJson()
        ..['updatedAt'] = ServerValue.timestamp;
      await _userRef(current.uid).update(data);
    } on FirebaseException catch (e) {
      throw AuthFailure(e.message ?? 'Could not save your changes.');
    }

    return toSave;
  }

  @override
  Future<AuthUser> continueAsGuest() async {
    // Prefer a real anonymous Firebase session, but if anonymous sign-in isn't
    // enabled / available, fall back to a local guest so the user can still
    // browse as a guest instead of being blocked.
    try {
      final result = await _auth.signInAnonymously();
      return AuthUser(id: result.user?.uid, isGuest: true);
    } on FirebaseAuthException {
      return const AuthUser.guest();
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Maps a Firebase [User] to the domain [AuthUser]; `null` stays `null`.
  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.uid,
      isGuest: user.isAnonymous,
      mobile:
          user.phoneNumber ??
          (_sessionMobiles.isNotEmpty ? _sessionMobiles.values.last : null),
      email: user.email,
    );
  }
}
