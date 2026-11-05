import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_access_repository.dart';

/// Holds the signed-in admin's account (name + mobile) for display in the
/// portal. Loads from the Firebase `admin` node via [AdminAccessRepository].
///
/// The state is nullable: null means "not resolved / not an admin". The portal
/// falls back to a generic label when it is null.
class AdminSessionCubit extends Cubit<AdminAccount?> {
  AdminSessionCubit(this._repository) : super(null);

  final AdminAccessRepository _repository;

  /// Looks up the admin record for [mobile] and stores it.
  Future<void> load(String? mobile) async {
    final AdminAccount? account = await _repository.lookupAdmin(mobile);
    emit(account);
  }
}
