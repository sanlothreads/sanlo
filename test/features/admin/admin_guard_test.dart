import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanlo/core/router/app_routes.dart';
import 'package:sanlo/features/admin/presentation/widgets/admin_bottom_nav.dart';

import 'admin_guard_harness.dart';

/// Behaviour tests for the private `_AdminGuard` that wraps the admin
/// `StatefulShellRoute` in `appRouter`.
///
/// Tasks 7.1–7.9. The guard is private to `app_router.dart`, so every case
/// drives it through the real [appRouter] via [pumpAdminGuard] (see
/// `admin_guard_harness.dart`). The single 7.1 smoke test is folded into the
/// behaviour cases below.
///
/// "Admin content shown" is asserted via the [AdminBottomNav] that
/// `AdminShellHost` → `AdminShellScreen` renders in the narrow test layout
/// (the default 800px test surface is below `AppSpacing.wideBreakpoint` of
/// 900). It is a stable structural marker, so tests avoid asserting on admin
/// label text that may change.
void main() {
  // `verifyNever(() => stub.isAdmin(any()))` needs a registered fallback for
  // the nullable String argument matcher.
  setUpAll(() => registerFallbackValue(''));

  tearDown(resetAdminGuardRouter);

  /// Finder for a reliable admin-shell marker (present only once the guard
  /// grants access and `AdminShellHost` renders).
  final Finder adminShell = find.byType(AdminBottomNav);

  group('Admin guard (7.1–7.9)', () {
    testWidgets(
      '7.2 admin resolves → admin shell shown, no spinner, not denied',
      (WidgetTester tester) async {
        final GoRouter router = await pumpAdminGuard(
          tester,
          auth: authedWith(kAdminMobile),
        );

        await tester.pumpAndSettle();

        expect(adminShell, findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(currentLocation(router), Routes.adminDashboardPath);
        expect(currentLocation(router), isNot(Routes.accessDeniedPath));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7.3 loading before resolution → spinner, no admin content, not denied yet',
      (WidgetTester tester) async {
        final GoRouter router = await pumpAdminGuard(
          tester,
          auth: authedWith(kAdminMobile),
          access: NeverCompletingAdminAccessRepository(),
        );

        // Advance past the route-transition animation (but NOT pumpAndSettle —
        // the check never completes, so the guard stays pending forever).
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(adminShell, findsNothing);
        expect(currentLocation(router), isNot(Routes.accessDeniedPath));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7.4 authenticated non-admin → redirect to access-denied, no admin content',
      (WidgetTester tester) async {
        final GoRouter router = await pumpAdminGuard(
          tester,
          auth: authedWith(kNonAdminMobile),
        );

        await tester.pumpAndSettle();

        expect(currentLocation(router), Routes.accessDeniedPath);
        expect(adminShell, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('7.5 guest → redirect without an isAdmin lookup', (
      WidgetTester tester,
    ) async {
      final MockAdminAccessRepositoryStub stub =
          MockAdminAccessRepositoryStub();

      final GoRouter router = await pumpAdminGuard(
        tester,
        auth: guestState(),
        access: stub,
      );

      await tester.pumpAndSettle();

      expect(currentLocation(router), Routes.accessDeniedPath);
      expect(adminShell, findsNothing);
      // Short-circuit: guests never trigger a Firebase lookup (Req 4.3).
      verifyNever(() => stub.isAdmin(any()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('7.6 unauthenticated → redirect without an isAdmin lookup', (
      WidgetTester tester,
    ) async {
      final MockAdminAccessRepositoryStub stub =
          MockAdminAccessRepositoryStub();

      final GoRouter router = await pumpAdminGuard(
        tester,
        auth: unauthenticatedState(),
        access: stub,
      );

      await tester.pumpAndSettle();

      expect(currentLocation(router), Routes.accessDeniedPath);
      expect(adminShell, findsNothing);
      verifyNever(() => stub.isAdmin(any()));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '7.7 lookup error → fail closed, redirect to access-denied, no admin content',
      (WidgetTester tester) async {
        final GoRouter router = await pumpAdminGuard(
          tester,
          auth: authedWith(kAdminMobile),
          access: ThrowingAdminAccessRepository(),
        );

        await tester.pumpAndSettle();

        expect(currentLocation(router), Routes.accessDeniedPath);
        expect(adminShell, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7.8 deep-link entry to admin dashboard is gated for non-admin',
      (WidgetTester tester) async {
        final GoRouter router = await pumpAdminGuard(
          tester,
          auth: authedWith(kNonAdminMobile),
          location: Routes.adminDashboardPath,
        );

        await tester.pumpAndSettle();

        expect(currentLocation(router), Routes.accessDeniedPath);
        expect(adminShell, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '7.9 nested product-new route is gated by the single wrapper for non-admin',
      (WidgetTester tester) async {
        final GoRouter router = await pumpAdminGuard(
          tester,
          auth: authedWith(kNonAdminMobile),
          location: Routes.adminProductNewPath,
        );

        await tester.pumpAndSettle();

        expect(currentLocation(router), Routes.accessDeniedPath);
        expect(adminShell, findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
