import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanlo/core/router/app_routes.dart';
import 'package:sanlo/features/admin/domain/repositories/admin_access_repository.dart';
import 'package:sanlo/features/admin/presentation/widgets/admin_bottom_nav.dart';
import 'package:sanlo/features/auth/presentation/bloc/auth_bloc.dart';

import 'admin_guard_harness.dart';

/// Correctness-property tests for the admin access guard (Tasks 8.1, 8.2).
///
/// Both properties are decision invariants over a small, enumerable input
/// space (auth state × admin-check outcome), so — per the design's Testing
/// Strategy — they are realised as parameterized widget tests that cover each
/// case exactly once rather than randomized ≥100-iteration generators.
///
/// "Admin content shown" is asserted via the [AdminBottomNav] marker that
/// `AdminShellHost` renders in the narrow test layout.
void main() {
  /// A reliable admin-shell marker (present only once access is granted).
  final Finder adminShell = find.byType(AdminBottomNav);

  tearDown(resetAdminGuardRouter);

  // ---------------------------------------------------------------------------
  // Property 1: Admin content shown iff authenticated admin.
  // ---------------------------------------------------------------------------
  group(
    'Feature: admin-access-guard, Property 1: Admin content shown iff authenticated admin',
    () {
      for (final _GuardCase c in _property1Cases) {
        testWidgets(
          'Feature: admin-access-guard, Property 1: Admin content shown iff '
          'authenticated admin — case: ${c.name}',
          (WidgetTester tester) async {
            await pumpAdminGuard(tester, auth: c.auth, access: c.access);

            if (c.pending) {
              // Unresolved: advance past the route-transition animation, but
              // do NOT settle — the check never completes.
              await tester.pump(const Duration(seconds: 1));
              expect(find.byType(CircularProgressIndicator), findsOneWidget);
              expect(adminShell, findsNothing);
            } else {
              await tester.pumpAndSettle();
              if (c.isAdminGranted) {
                // Admin content shown iff authenticated admin.
                expect(adminShell, findsOneWidget);
              } else {
                // Every other resolved case withholds admin content.
                expect(adminShell, findsNothing);
              }
            }

            expect(tester.takeException(), isNull);
          },
        );
      }
    },
  );

  // ---------------------------------------------------------------------------
  // Property 2: Every deny outcome routes to Access Denied.
  // ---------------------------------------------------------------------------
  group(
    'Feature: admin-access-guard, Property 2: Every deny outcome routes to Access Denied',
    () {
      for (final _GuardCase c in _property2DenyCases) {
        testWidgets(
          'Feature: admin-access-guard, Property 2: Every deny outcome routes '
          'to Access Denied — case: ${c.name}',
          (WidgetTester tester) async {
            final GoRouter router = await pumpAdminGuard(
              tester,
              auth: c.auth,
              access: c.access,
            );

            await tester.pumpAndSettle();

            expect(currentLocation(router), Routes.accessDeniedPath);
            expect(tester.takeException(), isNull);
          },
        );
      }
    },
  );
}

/// One enumerated guard scenario: an [AuthState] × admin-check outcome.
class _GuardCase {
  const _GuardCase({
    required this.name,
    required this.auth,
    this.access,
    this.pending = false,
    this.isAdminGranted = false,
  });

  final String name;
  final AuthState auth;

  /// The injected repository double; `null` uses the seeded mock.
  final AdminAccessRepository? access;

  /// True for the never-completing (loading) case — do not settle.
  final bool pending;

  /// True only for the authenticated-admin case that resolves to granted.
  final bool isAdminGranted;
}

/// Property 1 input space: {pending, admin, non-admin, unauthenticated, guest,
/// error}.
final List<_GuardCase> _property1Cases = <_GuardCase>[
  _GuardCase(
    name: 'pending',
    auth: authedWith(kAdminMobile),
    access: NeverCompletingAdminAccessRepository(),
    pending: true,
  ),
  _GuardCase(
    name: 'admin',
    auth: authedWith(kAdminMobile),
    isAdminGranted: true,
  ),
  _GuardCase(name: 'non-admin', auth: authedWith(kNonAdminMobile)),
  _GuardCase(name: 'unauthenticated', auth: unauthenticatedState()),
  _GuardCase(name: 'guest', auth: guestState()),
  _GuardCase(
    name: 'error',
    auth: authedWith(kAdminMobile),
    access: ThrowingAdminAccessRepository(),
  ),
];

/// Property 2 input space: the four deny cases.
final List<_GuardCase> _property2DenyCases = <_GuardCase>[
  _GuardCase(name: 'non-admin', auth: authedWith(kNonAdminMobile)),
  _GuardCase(name: 'unauthenticated', auth: unauthenticatedState()),
  _GuardCase(name: 'guest', auth: guestState()),
  _GuardCase(
    name: 'error',
    auth: authedWith(kAdminMobile),
    access: ThrowingAdminAccessRepository(),
  ),
];
