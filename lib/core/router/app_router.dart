import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/admin/domain/entities/admin_product.dart';
import '../../features/admin/domain/repositories/admin_access_repository.dart';
import '../../features/admin/presentation/screens/access_denied_screen.dart';
import '../../features/admin/presentation/screens/admin_customers_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_product_form_screen.dart';
import '../../features/admin/presentation/screens/admin_products_screen.dart';
import '../../features/admin/presentation/screens/admin_shell_host.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/catalog/domain/entities/product.dart';
import '../../features/catalog/presentation/screens/home_screen.dart';
import '../../features/catalog/presentation/screens/product_details_screen.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/presentation/bloc/place_order_bloc.dart';
import '../../features/orders/presentation/bloc/place_order_event.dart';
import '../../features/orders/presentation/screens/order_details_step_screen.dart';
import '../../features/orders/presentation/screens/my_orders_screen.dart';
import '../../features/orders/presentation/screens/order_measurements_step_screen.dart';
import '../../features/orders/presentation/screens/order_placed_screen.dart';
import '../../features/orders/presentation/screens/order_review_step_screen.dart';
import '../../features/orders/presentation/screens/order_tracking_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/shell/presentation/screens/main_shell_screen.dart';
import 'app_routes.dart';

/// The app's single `GoRouter` instance.
///
/// This is a top-level final so it can be handed to `MaterialApp.router`
/// directly. The order sub-flow's `ShellRoute` reads [OrderRepository] from
/// the widget tree via `context.read()`, so this router must be used *below* a
/// `RepositoryProvider<OrderRepository>` (wired in `app.dart`). Because the
/// repository is resolved lazily when the `/order` subtree is first built,
/// constructing the router eagerly here is safe.
final GoRouter appRouter = _buildRouter();

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: Routes.splashPath,
    routes: <RouteBase>[
      // --- Splash (shown for 2s, then routes to Sign in) ---------------------
      GoRoute(
        path: Routes.splashPath,
        name: Routes.splashName,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),

      // --- Auth (top-level, above the shell) ---------------------------------
      GoRoute(
        path: Routes.signInPath,
        name: Routes.signInName,
        builder: (BuildContext context, GoRouterState state) =>
            const SignInScreen(),
      ),
      GoRoute(
        path: Routes.signUpPath,
        name: Routes.signUpName,
        builder: (BuildContext context, GoRouterState state) =>
            SignUpScreen(signedInUser: state.extra as AuthUser?),
      ),

      // --- 3-tab bottom-navigation shell -------------------------------------
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) => MainShellScreen(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.homePath,
                name: Routes.homeName,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.ordersPath,
                name: Routes.ordersName,
                builder: (BuildContext context, GoRouterState state) =>
                    const MyOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.profilePath,
                name: Routes.profileName,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Admin 4-tab shell --------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) => _AdminGuard(
              child: AdminShellHost(navigationShell: navigationShell),
            ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.adminDashboardPath,
                name: Routes.adminDashboardName,
                builder: (BuildContext context, GoRouterState state) =>
                    AdminDashboardScreen(
                      onAddProduct: () =>
                          context.goNamed(Routes.adminProductNewName),
                      onViewAllOrders: () =>
                          context.goNamed(Routes.adminOrdersName),
                    ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.adminOrdersPath,
                name: Routes.adminOrdersName,
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.adminProductsPath,
                name: Routes.adminProductsName,
                builder: (BuildContext context, GoRouterState state) =>
                    AdminProductsScreen(
                      onAddProduct: () =>
                          context.pushNamed(Routes.adminProductNewName),
                      onEditProduct: (AdminProduct p) => context.pushNamed(
                        Routes.adminProductEditName,
                        pathParameters: <String, String>{'id': p.id},
                        extra: p,
                      ),
                    ),
                routes: <RouteBase>[
                  // Nested under the products branch so the form shares the
                  // branch's AdminProductsCubit and upserts are reflected.
                  GoRoute(
                    path: 'new',
                    name: Routes.adminProductNewName,
                    builder: (BuildContext context, GoRouterState state) =>
                        AdminProductFormScreen(onDone: () => context.pop()),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: Routes.adminProductEditName,
                    builder: (BuildContext context, GoRouterState state) =>
                        AdminProductFormScreen(
                          product: state.extra as AdminProduct?,
                          onDone: () => context.pop(),
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.adminCustomersPath,
                name: Routes.adminCustomersName,
                builder: (BuildContext context, GoRouterState state) =>
                    const AdminCustomersScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Access denied (top-level, sibling of the admin shell) --------------
      GoRoute(
        path: Routes.accessDeniedPath,
        name: Routes.accessDeniedName,
        builder: (BuildContext context, GoRouterState state) =>
            const AccessDeniedScreen(),
      ),

      // --- Product details ----------------------------------------------------
      GoRoute(
        path: Routes.productDetailsPath,
        name: Routes.productDetailsName,
        builder: (BuildContext context, GoRouterState state) =>
            ProductDetailsScreen(productId: state.pathParameters['id']!),
      ),

      // --- Order sub-flow -----------------------------------------------------
      // A single PlaceOrderBloc is provided above all three step routes so the
      // OrderDraft (product + details + measurements) is preserved across them.
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return BlocProvider<PlaceOrderBloc>(
            create: (_) => PlaceOrderBloc(
              orderRepository: context.read<OrderRepository>(),
            ),
            child: child,
          );
        },
        routes: <RouteBase>[
          // Step 1: entered with the Product via `extra`. The entry widget
          // dispatches OrderStarted into the shared bloc when the draft has
          // not been started yet.
          GoRoute(
            path: Routes.orderDetailsPath,
            name: Routes.orderDetailsName,
            builder: (BuildContext context, GoRouterState state) =>
                _OrderDetailsEntry(product: state.extra as Product?),
          ),
          // Step 2: guarded — needs a started draft with a product.
          GoRoute(
            path: Routes.orderMeasurementsPath,
            name: Routes.orderMeasurementsName,
            builder: (BuildContext context, GoRouterState state) =>
                const _OrderGuard(child: OrderMeasurementsStepScreen()),
          ),
          // Step 3: guarded — needs a started draft with a product.
          GoRoute(
            path: Routes.orderReviewPath,
            name: Routes.orderReviewName,
            builder: (BuildContext context, GoRouterState state) =>
                const _OrderGuard(child: OrderReviewStepScreen()),
          ),
        ],
      ),

      // --- Order outcome ------------------------------------------------------
      GoRoute(
        path: Routes.orderPlacedPath,
        name: Routes.orderPlacedName,
        builder: (BuildContext context, GoRouterState state) =>
            OrderPlacedScreen(orderId: state.uri.queryParameters['id']!),
      ),
      GoRoute(
        path: Routes.orderTrackingPath,
        name: Routes.orderTrackingName,
        builder: (BuildContext context, GoRouterState state) =>
            OrderTrackingScreen(orderId: state.pathParameters['id']!),
      ),
    ],
  );
}

/// Step-1 entry widget for the order flow.
///
/// The shared [PlaceOrderBloc] is created by the parent `ShellRoute` builder,
/// so it is available as an ancestor here. On first build we dispatch
/// [OrderStarted] (seeding the draft with the [product] passed via the route's
/// `extra`) when the flow has not been started yet. Dispatching an event is
/// done in [initState] — not in `build` — so it runs exactly once and never
/// during a build phase.
class _OrderDetailsEntry extends StatefulWidget {
  const _OrderDetailsEntry({required this.product});

  /// The product to order, forwarded from `GoRouterState.extra`. Null when the
  /// route was reached without a product (e.g. deep-link / refresh).
  final Product? product;

  @override
  State<_OrderDetailsEntry> createState() => _OrderDetailsEntryState();
}

class _OrderDetailsEntryState extends State<_OrderDetailsEntry> {
  @override
  void initState() {
    super.initState();
    final Product? product = widget.product;
    final PlaceOrderBloc bloc = context.read<PlaceOrderBloc>();
    // Only start a fresh draft; avoid clobbering an in-progress one when the
    // user navigates back to step 1 to edit.
    if (product != null && bloc.state.draft == null) {
      bloc.add(OrderStarted(product: product));
    }
  }

  @override
  Widget build(BuildContext context) =>
      OrderDetailsStepScreen(entryProduct: widget.product);
}

/// Guard wrapper for order steps 2 and 3.
///
/// `redirect` cannot access the per-subtree [PlaceOrderBloc] (it is provided by
/// the `ShellRoute` builder, below the redirect's reach), so the guard lives
/// here in the widget tree instead. If the shared draft has no product (the
/// flow was never started — e.g. direct deep-link), it schedules a navigation
/// back to Home after the current frame and renders nothing in the meantime.
class _OrderGuard extends StatelessWidget {
  const _OrderGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final PlaceOrderBloc bloc = context.read<PlaceOrderBloc>();
    final bool hasProduct = bloc.state.draft?.product != null;

    if (!hasProduct) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.goNamed(Routes.homeName);
        }
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}

/// Tri-state resolution of the admin authorization check.
enum _AdminAccess { pending, granted, denied }

/// Minimal full-screen loading view shown while the admin check is unresolved
/// and during the one-frame window before a scheduled redirect takes effect.
class _AdminGuardLoading extends StatelessWidget {
  const _AdminGuardLoading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// Authorization gate for the entire `/admin/...` subtree.
///
/// `redirect` is synchronous and cannot await [AdminAccessRepository.isAdmin],
/// and it cannot render a loading indicator. So — mirroring [_OrderGuard] — the
/// gate lives in the widget tree. On first build it short-circuits
/// unauthenticated/guest users (no Firebase lookup), otherwise kicks off the
/// async admin check in [initState]. While unresolved it shows a spinner; on
/// "admin" it renders the admin shell child; on not-admin / error /
/// unauthenticated / guest it schedules a post-frame redirect to
/// `/access-denied`. Fails closed on error.
class _AdminGuard extends StatefulWidget {
  const _AdminGuard({required this.child});

  /// The admin shell host to render once access is granted.
  final Widget child;

  @override
  State<_AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<_AdminGuard> {
  _AdminAccess _access = _AdminAccess.pending;

  @override
  void initState() {
    super.initState();
    final AuthState auth = context.read<AuthBloc>().state;

    // Short-circuit: unauthenticated or guest → deny without a Firebase lookup.
    // isAuthenticated is false for guests and no-session users.
    if (!auth.isAuthenticated) {
      _access = _AdminAccess.denied;
      return; // build() will schedule the redirect
    }

    _resolve(auth.user?.mobile); // async; updates _access via setState
  }

  Future<void> _resolve(String? mobile) async {
    try {
      final AdminAccessRepository access = context
          .read<AdminAccessRepository>();
      final bool isAdmin = await access.isAdmin(mobile);
      if (!mounted) return;
      setState(
        () => _access = isAdmin ? _AdminAccess.granted : _AdminAccess.denied,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _access = _AdminAccess.denied); // Fail closed.
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_access) {
      case _AdminAccess.granted:
        return widget.child;
      case _AdminAccess.pending:
        return const _AdminGuardLoading();
      case _AdminAccess.denied:
        // Schedule the redirect after this frame — never navigate during build
        // (mirrors _OrderGuard). Withhold admin content meanwhile.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.goNamed(Routes.accessDeniedName);
          }
        });
        return const _AdminGuardLoading();
    }
  }
}
