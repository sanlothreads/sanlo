import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

/// Drives the Profile screen: loads the profile + order stats and manages the
/// (optional) edit/save flow for personal details.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState.initial());

  final ProfileRepository _repository;

  /// Loads the current customer's profile and stats.
  ///
  /// Emits a loading state first, then a populated state on success, or an
  /// error state if the fetch fails.
  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final profile = await _repository.getProfile();
      emit(state.copyWith(loading: false, profile: profile));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  /// Enters edit mode for the personal-details form.
  void startEditing() {
    emit(state.copyWith(editing: true));
  }

  /// Leaves edit mode without saving changes.
  void cancelEditing() {
    emit(state.copyWith(editing: false));
  }

  /// Persists [updated] via the repository and leaves edit mode on success.
  ///
  /// Emits the saved profile with editing cleared, or an error state if the
  /// update fails.
  Future<void> save(UserProfile updated) async {
    emit(state.copyWith(loading: true));
    try {
      final saved = await _repository.updateProfile(updated);
      emit(state.copyWith(loading: false, profile: saved, editing: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
