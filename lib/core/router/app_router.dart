import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
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
            const SignUpScreen(),
      ),

      // --- 3-tab bottom-navigation shell -------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) =>
            MainShellScreen(navigationShell: navigationShell),
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
