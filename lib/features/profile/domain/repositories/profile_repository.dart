import '../entities/user_profile.dart';

/// Contract for reading and updating the signed-in customer's profile.
abstract interface class ProfileRepository {
  /// Returns the current customer's profile.
  Future<UserProfile> getProfile();

  /// Persists [profile] and returns the updated profile (mock: echoes back).
  Future<UserProfile> updateProfile(UserProfile profile);
}
