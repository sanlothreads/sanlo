import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/catalog/domain/repositories/product_repository.dart';
import 'features/orders/domain/repositories/order_repository.dart';
import 'features/profile/domain/repositories/profile_repository.dart';

/// Root widget of the Sanlo app.
///
/// This is the composition point where the app is wired together:
///
///  * [ServiceLocator] is constructed once and hands out the four repositories
///    typed as their domain *interfaces*. They are published to the widget
///    tree via `RepositoryProvider.value` so a single shared instance is used
///    everywhere — important for [OrderRepository], whose in-memory mock must
///    persist a placed order across the "My orders" / tracking screens.
///  * The [RepositoryProvider]s sit *above* [MaterialApp.router] because
///    [appRouter]'s order sub-flow resolves [OrderRepository] from the widget
///    tree via `context.read()`.
///  * A global [AuthBloc] is provided above the router as well, since the sign
///    in / sign up screens read it with `context.read<AuthBloc>()`.
class SanloApp extends StatelessWidget {
  const SanloApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ServiceLocator locator = ServiceLocator();
    return MultiRepositoryProvider(
      providers: <RepositoryProvider>[
        RepositoryProvider<AuthRepository>.value(
          value: locator.authRepository,
        ),
        RepositoryProvider<ProductRepository>.value(
          value: locator.productRepository,
        ),
        RepositoryProvider<OrderRepository>.value(
          value: locator.orderRepository,
        ),
        RepositoryProvider<ProfileRepository>.value(
          value: locator.profileRepository,
        ),
      ],
      child: BlocProvider<AuthBloc>(
        create: (BuildContext context) =>
            AuthBloc(authRepository: context.read<AuthRepository>()),
        child: MaterialApp.router(
          title: 'Sanlo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
