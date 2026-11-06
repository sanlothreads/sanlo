import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanlo/core/router/app_router.dart';
import 'package:sanlo/core/router/app_routes.dart';
import 'package:sanlo/features/admin/data/repositories/mock_admin_access_repository.dart';
import 'package:sanlo/features/admin/data/repositories/mock_admin_repository.dart';
import 'package:sanlo/features/admin/domain/repositories/admin_access_repository.dart';
import 'package:sanlo/features/admin/domain/repositories/admin_repository.dart';
import 'package:sanlo/features/admin/presentation/widgets/admin_bottom_nav.dart';
import 'package:sanlo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sanlo/features/catalog/data/repositories/mock_product_repository.dart';
import 'package:sanlo/features/catalog/domain/repositories/product_repository.dart';

import '../admin/admin_guard_harness.dart';

/// No-regression check for splash-time admin routing (Task 9, Req 7.1/7.2).
///
/// There is no pre-existing splash routing test in the suite, so this minimal
/// widget test pins the behaviour the admin guard must not regress: at splash
/// time an admin is routed to `adminDashboard` and a non-admin to Home. It
/// reuses the admin guard harness helpers ([authBlocWithState], [authedWith],
/// the seeded admin/non-admin numbers) and [MockAdminAccessRepository] so the
/// setup matches the rest of the admin tests.
///
/// The test drives the production [appRouter] from the splash location so the
/// real `SplashScreen._routeOnward` logic runs: it mounts the three providers
/// the splash and the downstream admin shell read (`AuthBloc`,
/// `AdminAccessRepository`, `AdminRepository`), advances past the 2s splash
/// timer, and settles the async admin lookup before asserting the destination.
void main() {
  tearDown(resetAdminGuardRouter);

  /// Mounts [appRouter] at the splash location under the providers the splash
  /// screen and the splash destinations read: `AuthBloc` +
  /// `AdminAccessRepository` for the splash routing decision, `AdminRepository`
  /// for the admin shell an admin lands on, and `ProductRepository` for the
  /// Home screen a non-admin lands on.
  Future<GoRouter> pumpSplash(
    WidgetTester tester, {
    required String adminMobile,
  }) async {
    final AdminAccessRepository accessRepo = MockAdminAccessRepository();
    final AdminRepository adminRepo = MockAdminRepository();
    final ProductRepository productRepo = MockProductRepository();
    final FakeAuthBloc authBloc = authBlocWithState(authedWith(adminMobile));

    // Ensure we start on the splash route (the shared router is a singleton).
    appRouter.go(Routes.splashPath);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: <RepositoryProvider>[
          RepositoryProvider<AdminAccessRepository>.value(value: accessRepo),
          RepositoryProvider<AdminRepository>.value(value: adminRepo),
          RepositoryProvider<ProductRepository>.value(value: productRepo),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(routerConfig: appRouter),
        ),
      ),
    );

    return appRouter;
  }

  testWidgets(
    'admin is routed to the admin dashboard at splash time (Req 7.1)',
    (WidgetTester tester) async {
      final GoRouter router = await pumpSplash(
        tester,
        adminMobile: kAdminMobile,
      );

      // Advance past the 2s splash delay, then settle the async admin lookup
      // (splash check + the admin guard's own re-check once the shell mounts).
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(currentLocation(router), Routes.adminDashboardPath);
      // The admin shell actually renders (guard granted access), confirming the
      // splash → admin route still lands on admin content.
      expect(find.byType(AdminBottomNav), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('non-admin is routed to Home at splash time (Req 7.2)', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpSplash(
      tester,
      adminMobile: kNonAdminMobile,
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(currentLocation(router), Routes.homePath);
    expect(find.byType(AdminBottomNav), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
