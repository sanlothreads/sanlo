import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanlo/core/router/app_routes.dart';
import 'package:sanlo/core/widgets/primary_button.dart';
import 'package:sanlo/features/admin/presentation/screens/access_denied_screen.dart';

void main() {
  group('AccessDeniedScreen', () {
    // Exact message required by Req 6.2.
    const String kMessage =
        "Access Denied — you don't have permission to access this page";

    testWidgets(
        'presents the exact access-denied message and a single "Go to Home" button',
        (WidgetTester tester) async {
      // Pump the screen on its own (Req 6.2, 6.3).
      await tester.pumpWidget(
        const MaterialApp(home: AccessDeniedScreen()),
      );
      await tester.pumpAndSettle();

      // Req 6.2 — the exact message text is present.
      expect(find.text(kMessage), findsOneWidget);

      // Req 6.3 — exactly one PrimaryButton labelled "Go to Home".
      final Finder primaryButtons = find.byType(PrimaryButton);
      expect(primaryButtons, findsOneWidget);
      expect(
        tester.widget<PrimaryButton>(primaryButtons).label,
        'Go to Home',
      );
    });

    testWidgets(
        'tapping "Go to Home" navigates to the home route',
        (WidgetTester tester) async {
      // Minimal router with an access-denied route and a home route (Req 6.4).
      final GoRouter router = GoRouter(
        initialLocation: Routes.accessDeniedPath,
        routes: <RouteBase>[
          GoRoute(
            path: Routes.accessDeniedPath,
            name: Routes.accessDeniedName,
            builder: (BuildContext context, GoRouterState state) =>
                const AccessDeniedScreen(),
          ),
          GoRoute(
            path: Routes.homePath,
            name: Routes.homeName,
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      // Sanity: we start on the access-denied route.
      expect(find.text(kMessage), findsOneWidget);

      // Tap the single action labelled "Go to Home".
      await tester.tap(find.widgetWithText(PrimaryButton, 'Go to Home'));
      await tester.pumpAndSettle();

      // Req 6.4 — current location is Routes.homePath.
      final String location = router
          .routerDelegate.currentConfiguration.uri
          .toString();
      expect(location, Routes.homePath);
    });
  });
}
