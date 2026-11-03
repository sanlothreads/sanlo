import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:sanlo/core/theme/app_colors.dart';
import 'package:sanlo/core/theme/app_spacing.dart';
import 'package:sanlo/core/widgets/filter_chips.dart';
import 'package:sanlo/core/widgets/product_card.dart';
import 'package:sanlo/features/catalog/domain/entities/product.dart';
import 'package:sanlo/features/catalog/domain/repositories/product_repository.dart';
import 'package:sanlo/features/catalog/presentation/cubit/home_cubit.dart';
import 'package:sanlo/features/catalog/presentation/cubit/home_state.dart';

/// The Home tab — the catalog browsing screen ("Home / all categories" mockup).
///
/// Shows a greeting header with a guest "Sign in" action, a search field, the
/// [CategoryFilterChips] row, a promo banner, and a 2-column grid of
/// [ProductCard]s driven by [HomeCubit].
///
/// The bottom navigation bar is provided by the shell scaffold, so this screen
/// only renders the Home tab content inside a plain [Scaffold].
///
/// The [HomeCubit] is provided locally, reading the [ProductRepository] from
/// the widget tree and kicking off [HomeCubit.load] immediately.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (context) => HomeCubit(context.read<ProductRepository>())..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(toolbarHeight: 0),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(child: _Header()),
              const SliverToBoxAdapter(child: _SearchField()),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              SliverToBoxAdapter(
                child: CategoryFilterChips(
                  categories: state.categories,
                  selected: state.selectedFilter,
                  onSelected: (kind) =>
                      context.read<HomeCubit>().applyFilter(kind),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              const SliverToBoxAdapter(child: _PromoBanner()),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              _PopularSection(state: state),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          );
        },
      ),
    );
  }
}

/// Greeting header with a top-right guest "Sign in" button.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Hello, Guest',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'What shall we stitch?',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: () => context.pushNamed('signIn'),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

/// Rounded search field that forwards changes to [HomeCubit.search].
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: TextField(
        onChanged: (text) => context.read<HomeCubit>().search(text),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search blouse, kurta, shirt…',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: AppRadius.pillAll,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.pillAll,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.pillAll,
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// Indigo promo banner inviting shop measurement + pay-at-shop.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: AppSpacing.pagePadding,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.xlAll,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.smd),
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.15),
                borderRadius: AppRadius.mdAll,
              ),
              child: const Icon(
                Icons.straighten_rounded,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Not sure of your size?',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Order now and visit the shop – we'll measure you. "
                    'Pay at the shop.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Popular right now" header + the loading / error / grid body.
class _PopularSection extends StatelessWidget {
  const _PopularSection({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Center(
            child: Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ),
      );
    }

    final List<Product> products = state.visibleProducts;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Popular right now',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${products.length} styles',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverPadding(
          padding: AppSpacing.pagePadding,
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.58,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final Product product = products[index];
              return ProductCard(
                product: product,
                colorIndex: index,
                onTap: () => context.pushNamed(
                  'productDetails',
                  pathParameters: {'id': product.id},
                ),
              );
            }, childCount: products.length),
          ),
        ),
      ],
    );
  }
}
