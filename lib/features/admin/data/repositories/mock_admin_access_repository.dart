import '../../domain/repositories/admin_access_repository.dart';

/// In-memory [AdminAccessRepository] seeded with the admin entries from the
/// Firebase `admin` node, used in tests and when running without a live
/// database.
class MockAdminAccessRepository implements AdminAccessRepository {
  MockAdminAccessRepository({Map<String, String>? admins})
      : _admins = admins ??
            const <String, String>{
              '+917665773775': 'SANLO THREADS',
              '+919137790025': 'HIMANSHU KUMAWAT',
            };

  /// Map of admin mobile (any format) to display name.
  final Map<String, String> _admins;

  @override
  Future<bool> isAdmin(String? mobile) async =>
      (await lookupAdmin(mobile)) != null;

  @override
  Future<AdminAccount?> lookupAdmin(String? mobile) async {
    final String target = normalizeMobile(mobile);
    if (target.isEmpty) return null;
    for (final MapEntry<String, String> e in _admins.entries) {
      if (normalizeMobile(e.key) == target) {
        return AdminAccount(name: e.value, mobile: e.key);
      }
    }
    return null;
  }
}
