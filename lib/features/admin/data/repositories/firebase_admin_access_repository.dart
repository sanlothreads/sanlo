import 'package:firebase_database/firebase_database.dart';

import '../../domain/repositories/admin_access_repository.dart';

/// Reads the Realtime Database `admin` node and checks whether a mobile number
/// matches one of the admin entries, returning the matching record's name.
///
/// Expected shape (matches the console):
/// ```
/// admin/
///   Admin1/ { mobile: "+917665773775", name: "SANLO THREADS" }
///   Admin2/ { mobile: "+919137790025", name: "HIMANSHU KUMAWAT" }
/// ```
/// Comparison is done on the last 10 digits via [normalizeMobile], so stored
/// values with or without the +91 prefix still match the signed-in number.
class FirebaseAdminAccessRepository implements AdminAccessRepository {
  FirebaseAdminAccessRepository({FirebaseDatabase? database})
      : _injectedDb = database;

  final FirebaseDatabase? _injectedDb;

  FirebaseDatabase get _db => _injectedDb ?? FirebaseDatabase.instance;

  @override
  Future<bool> isAdmin(String? mobile) async =>
      (await lookupAdmin(mobile)) != null;

  @override
  Future<AdminAccount?> lookupAdmin(String? mobile) async {
    final String target = normalizeMobile(mobile);
    if (target.isEmpty) return null;

    try {
      final DataSnapshot snapshot = await _db.ref('admin').get();
      if (!snapshot.exists || snapshot.value == null) return null;

      final Object? value = snapshot.value;
      if (value is! Map) return null;

      for (final Object? entry in value.values) {
        if (entry is Map) {
          final Object? stored = entry['mobile'];
          if (stored is String && normalizeMobile(stored) == target) {
            final Object? name = entry['name'];
            return AdminAccount(
              name: name is String ? name : 'Admin',
              mobile: stored,
            );
          }
        }
      }
      return null;
    } catch (_) {
      // On any read error, fail closed (treat as non-admin) so a transient
      // issue never grants admin access.
      return null;
    }
  }
}
