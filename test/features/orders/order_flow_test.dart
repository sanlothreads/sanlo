import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanlo/core/router/app_routes.dart';
import 'package:sanlo/features/orders/data/repositories/mock_order_repository.dart';
import 'package:sanlo/features/orders/domain/repositories/order_repository.dart';
import 'package:sanlo/features/orders/presentation/bloc/place_order_bloc.dart';
import 'package:sanlo/features/orders/presentation/screens/order_details_step_screen.dart';

void main() {
  testWidgets('OrderDetailsStepScreen renders safely when draft is initialized asynchronously',
      (WidgetTester tester) async {
    final OrderRepository repository = MockOrderRepository();

    final GoRouter testRouter = GoRouter(
      initialLocation: Routes.orderDetailsPath,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.homePath,
          name: Routes.homeName,
          builder: (_, __) => const SizedBox.shrink(),
        ),
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return BlocProvider<PlaceOrderBloc>(
              create: (_) => PlaceOrderBloc(orderRepository: repository),
              child: child,
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: Routes.orderDetailsPath,
              name: Routes.orderDetailsName,
              builder: (BuildContext context, GoRouterState state) =>
                  const OrderDetailsStepScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      RepositoryProvider<OrderRepository>.value(
        value: repository,
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
