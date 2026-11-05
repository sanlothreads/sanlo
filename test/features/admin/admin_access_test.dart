import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/features/admin/data/repositories/mock_admin_access_repository.dart';
import 'package:sanlo/features/admin/domain/repositories/admin_access_repository.dart';

void main() {
  group('normalizeMobile', () {
    test('keeps last 10 digits, ignoring prefix and spacing', () {
      expect(normalizeMobile('+91 76657 73775'), '7665773775');
      expect(normalizeMobile('917665773775'), '7665773775');
      expect(normalizeMobile('7665773775'), '7665773775');
      expect(normalizeMobile(null), '');
      expect(normalizeMobile(''), '');
    });
  });

  group('MockAdminAccessRepository', () {
    final repo = MockAdminAccessRepository();

    test('matches seeded admin numbers in any format', () async {
      expect(await repo.isAdmin('+917665773775'), isTrue);
      expect(await repo.isAdmin('7665773775'), isTrue);
      expect(await repo.isAdmin('+91 91377 90025'), isTrue);
    });

    test('lookupAdmin returns the admin name', () async {
      final a = await repo.lookupAdmin('7665773775');
      expect(a, isNotNull);
      expect(a!.name, 'SANLO THREADS');
      final b = await repo.lookupAdmin('+919137790025');
      expect(b!.name, 'HIMANSHU KUMAWAT');
      expect(await repo.lookupAdmin('+919999999999'), isNull);
    });

    test('rejects non-admin and empty numbers', () async {
      expect(await repo.isAdmin('+919999999999'), isFalse);
      expect(await repo.isAdmin(null), isFalse);
      expect(await repo.isAdmin(''), isFalse);
    });
  });
}
