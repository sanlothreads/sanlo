import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanlo/core/router/app_router.dart';
import 'package:sanlo/core/router/app_routes.dart';
import 'package:sanlo/features/admin/data/repositories/mock_admin_access_repository.dart';
import 'package:sanlo/features/admin/data/repositories/mock_admin_repository.dart';
import 'package:sanlo/features/admin/domain/repositories/admin_access_repository.dart';
import 'package:sanlo/features/admin/domain/repositories/admin_repository.dart';
import 'package:sanlo/features/auth/domain/entities/auth_user.dart';
import 'package:sanlo/features/auth/presentation/bloc/auth_bloc.dart';

/// Reusable widget-test harness for exercising the private `_AdminGuard` that
/// wraps the admin `StatefulShellRoute` in [appRouter].
///
/// The guard is private to `app_router.dart`, so — per the design's Testing
/// Strategy note — tests drive it through the **real** [appRouter]: the harness
/// mounts the production router, then navigates into the `/admin/...` subtree,
/// which runs the shell builder and therefore the guard's `initState`.
///
/// The guard reads two ancestors via `context.read`:
///   * `AuthBloc`  — for `AuthState.isAuthenticated` and `user?.mobile`.
///   * `AdminAccessRepository` — for `isAdmin(mobile)`.
/// Once access is granted, `AdminShellHost` additionally reads an
/// `AdminRepository`. The harness provides all three above `MaterialApp.router`.
///
/// `AuthBloc` is supplied as a [FakeAuthBloc] (a `bloc_test` `MockBloc` with a
/// stubbed `state`), so tests inject any [AuthState] without constructing a
/// real `AuthRepository`. The guard only reads `.state` synchronously and never
/// subscribes to the stream, so a mock bloc is sufficient and keeps the harness
/// free of auth-layer wiring.
///
/// ### Shared-router hygiene
/// [appRouter] is a top-level singleton. Call [resetAdminGuardRouter] in a
/// `tearDown` (or at the top of each test) so one test's final location does
/// not leak into the next.

// --- Seeded admin / non-admin numbers (match MockAdminAccessRepository) ------

/// A mobile seeded as an admin in [MockAdminAccessRepository].
const String kAdminMobile = '+917665773775';

/// A second seeded admin mobile.
const String kAdminMobileAlt = '+919137790025';

/// A valid mobile that is *not* an admin.
const String kNonAdminMobile = '+919999999999';

// --- Fake AuthBloc -----------------------------------------------------------

/// A mock [AuthBloc] whose `state` is stubbed to a fixed [AuthState].
///
/// Backed by `bloc_test`'s [MockBloc] so no real [AuthRepository] is needed.
class FakeAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Builds a [FakeAuthBloc] that reports [state] from `.state`.
FakeAuthBloc authBlocWithState(AuthState state) {
  final FakeAuthBloc bloc = FakeAuthBloc();
  when(() => bloc.state).thenReturn(state);
  return bloc;
}

// --- Canned auth states ------------------------------------------------------

/// An authenticated (non-guest) user signed in with [mobile].
AuthState authedWith(String? mobile) => AuthState(
  phase: AuthPhase.authenticated,
  user: AuthUser(id: 'u_test', mobile: mobile),
);

/// A guest session (`isAuthenticated == false`).
AuthState guestState() =>
    const AuthState(phase: AuthPhase.authenticated, user: AuthUser.guest());

/// A signed-out / no-session state (`isAuthenticated == false`).
AuthState unauthenticatedState() => const AuthState.idle();

// --- Repository doubles ------------------------------------------------------

/// A mocktail mock of [AdminAccessRepository] for stubbing `isAdmin` behaviour
/// and for `verifyNever` assertions (e.g. guest/unauthenticated short-circuit).
class MockAdminAccessRepositoryStub extends Mock
    implements AdminAccessRepository {}

/// An [AdminAccessRepository] whose `isAdmin` never completes, so the guard
/// stays in its `pending` (loading) state.
class NeverCompletingAdminAccessRepository implements AdminAccessRepository {
  @override
  Future<bool> isAdmin(String? mobile) => Completer<bool>().future;

  @override
  Future<AdminAccount?> lookupAdmin(String? mobile) =>
      Completer<AdminAccount?>().future;
}

/// An [AdminAccessRepository] whose `isAdmin` always throws, to exercise the
/// fail-closed path (Req 5.1/5.2).
class ThrowingAdminAccessRepository implements AdminAccessRepository {
  @override
  Future<bool> isAdmin(String? mobile) async =>
      throw StateError('admin lookup failed');

  @override
  Future<AdminAccount?> lookupAdmin(String? mobile) async =>
      throw StateError('admin lookup failed');
}

// --- Harness -----------------------------------------------------------------

/// Mounts the real [appRouter] under the three providers the guard and the
/// admin shell need, then navigates to [location] (defaults to the admin
/// dashboard) so the guard's `initState` runs.
///
/// Pass [auth] to control the signed-in user the guard sees, and [access] to
/// control the admin-check outcome. When [access] is omitted a seeded
/// [MockAdminAccessRepository] is used. [adminRepo] backs [AdminShellHost] once
/// access is granted (defaults to [MockAdminRepository]).
///
/// The returned [GoRouter] is the shared [appRouter]; read its current location
/// with [currentLocation].
///
/// The harness pumps once after navigating (enough to show the loading state)
/// but does **not** `pumpAndSettle`, so callers can choose to observe the
/// pending/loading frame or settle the async check themselves.
Future<GoRouter> pumpAdminGuard(
  WidgetTester tester, {
  required AuthState auth,
  AdminAccessRepository? access,
  AdminRepository? adminRepo,
  String location = Routes.adminDashboardPath,
}) async {
  final AdminAccessRepository accessRepo =
      access ?? MockAdminAccessRepository();
  final AdminRepository admin = adminRepo ?? MockAdminRepository();
  final FakeAuthBloc authBloc = authBlocWithState(auth);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: <RepositoryProvider>[
        RepositoryProvider<AdminAccessRepository>.value(value: accessRepo),
        RepositoryProvider<AdminRepository>.value(value: admin),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    ),
  );

  // Drive into the admin subtree so the shell builder (and the guard) mounts.
  appRouter.go(location);
  await tester.pump();

  return appRouter;
}

/// The router's current location as a string (e.g. `/access-denied`).
String currentLocation(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

/// Resets the shared [appRouter] back to the splash location so test cases do
/// not leak navigation state into one another. Call from `tearDown`.
void resetAdminGuardRouter() => appRouter.go(Routes.splashPath);
