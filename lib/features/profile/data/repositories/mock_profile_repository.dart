import '../../../../core/entities/gender.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// In-memory mock implementation of [ProfileRepository].
///
/// Seeds a single customer profile (matching the Profile mockup) with order
/// stats and personal details. Edits made via [updateProfile] replace the
/// in-memory profile so they persist for the lifetime of the session.
/// Intended for local development and testing before a real backend is wired
/// in.
class MockProfileRepository implements ProfileRepository {
  /// The profile seeded to match the Profile mockup.
  static const UserProfile _seedProfile = UserProfile(
    firstName: 'Priya',
    lastName: 'Sharma',
    mobile: '+91 98765 43210',
    email: 'priya@example.com',
    gender: Gender.female,
    totalOrders: 5,
    inProgress: 3,
    ready: 1,
  );

  /// Mutable in-memory profile; starts at [_seedProfile] and is replaced by
  /// [updateProfile].
  UserProfile _profile = _seedProfile;

  @override
  Future<UserProfile> getProfile() async => _profile;

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _profile = profile;
    return _profile;
  }
}
