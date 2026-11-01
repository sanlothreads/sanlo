import 'package:equatable/equatable.dart';

import '../../domain/entities/user_profile.dart';

/// State for the Profile screen.
///
/// Holds the loaded [profile] (including order stats), whether the screen is
/// in [editing] mode, and any [error] to display.
class ProfileState extends Equatable {
  const ProfileState({
    this.loading = false,
    this.profile,
    this.editing = false,
    this.error,
  });

  /// Initial loading state shown while the profile is first fetched.
  const ProfileState.initial() : this(loading: true);

  /// Whether the profile is currently being loaded or saved.
  final bool loading;

  /// The loaded profile, or null before it has been fetched.
  final UserProfile? profile;

  /// Whether the personal-details form is in edit mode.
  final bool editing;

  /// Error message to display, or null when there is no error.
  final String? error;

  /// Returns a copy of this state with the given fields replaced.
  ///
  /// [error] is replaced on every call (not merged) so that a successful
  /// emit clears any previous error.
  ProfileState copyWith({
    bool? loading,
    UserProfile? profile,
    bool? editing,
    String? error,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      profile: profile ?? this.profile,
      editing: editing ?? this.editing,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, profile, editing, error];
}
