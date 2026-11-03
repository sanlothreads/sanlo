import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:sanlo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sanlo/features/orders/data/repositories/mock_order_repository.dart';
import 'package:sanlo/features/orders/domain/repositories/order_repository.dart';
import 'package:sanlo/features/orders/presentation/screens/my_orders_screen.dart';

void main() {
  testWidgets(
    'MyOrdersScreen builds and compiles semantics without parentData dirty errors',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        RepositoryProvider<OrderRepository>(
          create: (_) => MockOrderRepository(),
          // The screen reads the app-wide AuthBloc to decide guest vs signed-in.
          // A fresh (idle) bloc is an unauthenticated guest, so the guest banner
          // shows — matching the assertions below.
          child: BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(authRepository: MockAuthRepository()),
            child: const MaterialApp(home: MyOrdersScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My orders'), findsOneWidget);
      expect(
        find.textContaining('Sign in to see them on any device'),
        findsWidgets,
      );
      expect(find.textContaining('Sign in'), findsWidgets);

      handle.dispose();
    },
  );
}
