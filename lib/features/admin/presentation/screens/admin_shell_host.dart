import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/admin_access_repository.dart';
import '../../domain/repositories/admin_repository.dart';
import '../cubit/admin_customers_cubit.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_orders_cubit.dart';
import '../cubit/admin_products_cubit.dart';
import '../cubit/admin_session_cubit.dart';
import '../widgets/admin_destinations.dart';
import 'admin_shell_screen.dart';

/// Hosts the admin cubits above the admin [StatefulNavigationShell] and renders
/// the responsive [AdminShellScreen].
///
/// The cubits are created once here and load eagerly, so the branch screens
/// below simply `context.read`/`BlocBuilder` them. The [AdminSessionCubit]
/// resolves the signed-in admin's name (from the Firebase `admin` node) for
/// display. Destination taps drive `navigationShell.goBranch`; "Sign out"
/// dispatches [SignOutRequested] and returns to Sign in.
class AdminShellHost extends StatelessWidget {
  const AdminShellHost({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final AdminRepository repo = context.read<AdminRepository>();
    final AdminAccessRepository access =
        context.read<AdminAccessRepository>();
    final String? mobile = context.read<AuthBloc>().state.user?.mobile;

    return MultiBlocProvider(
      providers: <BlocProvider>[
        BlocProvider<AdminDashboardCubit>(
          create: (_) => AdminDashboardCubit(repo)..load(),
        ),
        BlocProvider<AdminOrdersCubit>(
          create: (_) => AdminOrdersCubit(repo)..load(),
        ),
        BlocProvider<AdminProductsCubit>(
          create: (_) => AdminProductsCubit(repo)..load(),
        ),
        BlocProvider<AdminCustomersCubit>(
          create: (_) => AdminCustomersCubit(repo)..load(),
        ),
        BlocProvider<AdminSessionCubit>(
          create: (_) => AdminSessionCubit(access)..load(mobile),
        ),
      ],
      child: BlocBuilder<AdminSessionCubit, AdminAccount?>(
        builder: (context, account) {
          return AdminShellScreen(
            adminName: account?.name,
            selected: AdminDestination.values[navigationShell.currentIndex],
            onSelect: (d) => navigationShell.goBranch(
              d.index,
              initialLocation: d.index == navigationShell.currentIndex,
            ),
            onSignOut: () {
              context.read<AuthBloc>().add(const SignOutRequested());
              context.goNamed(Routes.signInName);
            },
            child: navigationShell,
          );
        },
      ),
    );
  }
}
