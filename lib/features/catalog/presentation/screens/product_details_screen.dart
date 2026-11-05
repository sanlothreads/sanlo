import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/image_placeholder.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/style_detail.dart';
import '../../domain/repositories/product_repository.dart';
import '../cubit/product_details_cubit.dart';
import '../cubit/product_details_state.dart';

/// The Product details screen.
///
/// Shows a large photo area with variant thumbnails, the category/type/rating
/// line, price / ready-in / payment info chips, an "About this style" section,
/// an "Included" checklist, and a pinned bottom bar with the stitching charge
/// and an "Order now" CTA.
///
/// The [ProductDetailsCubit] is provided locally and loads the [StyleDetail]
/// for [productId] on creation. Tapping "Order now" navigates into the order
/// flow, passing the [Product] via `extra` so the order shell can start the
/// draft.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  /// The id of the product whose details are shown.
  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductDetailsCubit>(
      create: (c) =>
          ProductDetailsCubit(c.read<ProductRepository>())..load(productId),
      child: const _ProductDetailsView(),
    );
  }
}

class _ProductDetailsView extends StatelessWidget {
  const _ProductDetailsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: ResponsiveCenter(
        child: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error == 'Not found') {
              return const _NotFoundView();
            }

            final detail = state.detail;
            if (detail == null) {
              return const _NotFoundView();
            }

            return _LoadedView(state: state, detail: detail);
          },
        ),
      ),
    );
  }
}

/// Simple "Not found" state with a back action.
class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _CircleBackButton(onPressed: () => context.pop()),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Not found', style: textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'We could not find that style.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The fully-loaded content, including the pinned bottom order bar.
class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state, required this.detail});

  final ProductDetailsState state;
  final StyleDetail detail;

  @override
  Widget build(BuildContext context) {
    final product = detail.product;

    return SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _PhotoArea(
                    photoIndex: state.selectedPhotoIndex,
                    imageCount: product.imageCount,
                    imageUrls: product.imageUrls,
                  ),
                  if (detail.variantLabels.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    _VariantThumbnails(
                      variantLabels: detail.variantLabels,
                      selectedIndex: state.selectedVariantIndex,
                      imageUrls: product.imageUrls,
                    ),
                  ],
                  Padding(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.md),
                        _CategoryTypeLine(
                          categoryLabel: detail.categoryLabel,
                          typeLabel: product.typeLabel,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (product.shortDescription.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            product.shortDescription,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        _RatingLine(rating: product.rating),
                        const SizedBox(height: AppSpacing.md),
                        _InfoChipsRow(
                          priceInr: product.priceInr,
                          readyInDays: product.readyInDays,
                          paymentLabel: detail.paymentLabel,
                        ),
                        if (detail.highlights.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.lg),
                          const _SectionHeading('Highlights'),
                          const SizedBox(height: AppSpacing.sm),
                          _HighlightsChecklist(items: detail.highlights),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionHeading('About this style'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          detail.aboutText,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (detail.included.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.lg),
                          const _SectionHeading('Included'),
                          const SizedBox(height: AppSpacing.sm),
                          _IncludedChecklist(items: detail.included),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomOrderBar(
            stitchingChargeInr: detail.stitchingChargeInr,
            product: product,
          ),
        ],
      ),
    );
  }
}

/// Large top photo area with auto-scrolling vertical carousel and manual vertical scroll support.
class _PhotoArea extends StatefulWidget {
  const _PhotoArea({
    required this.photoIndex,
    required this.imageCount,
    required this.imageUrls,
  });

  final int photoIndex;
  final int imageCount;
  final List<String> imageUrls;

  @override
  State<_PhotoArea> createState() => _PhotoAreaState();
}

class _PhotoAreaState extends State<_PhotoArea> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.photoIndex);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _PhotoArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoIndex != widget.photoIndex &&
        _pageController.hasClients &&
        _pageController.page?.round() != widget.photoIndex) {
      _pageController.animateToPage(
        widget.photoIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    final int count = widget.imageUrls.isNotEmpty
        ? widget.imageUrls.length
        : widget.imageCount;
    if (count <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final int current = _pageController.page?.round() ?? 0;
      final int nextPage = (current + 1) % count;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.imageUrls.isNotEmpty
        ? widget.imageUrls.length
        : widget.imageCount;

    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppRadius.xl),
            bottomRight: Radius.circular(AppRadius.xl),
          ),
          child: SizedBox(
            height: 320,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: count,
              onPageChanged: (index) {
                context.read<ProductDetailsCubit>().selectVariant(index);
              },
              itemBuilder: (context, index) {
                final bool hasImage = index < widget.imageUrls.length;
                final String currentUrl = hasImage
                    ? widget.imageUrls[index]
                    : '';

                if (hasImage && currentUrl.isNotEmpty) {
                  return Image.network(
                    currentUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 320,
                    errorBuilder: (ctx, err, stack) => ImagePlaceholder(
                      height: 320,
                      width: double.infinity,
                      borderRadius: BorderRadius.zero,
                      backgroundColor: AppColors.cardLavender,
                      caption: '[Photo ${index + 1} of $count]',
                    ),
                  );
                }

                return ImagePlaceholder(
                  height: 320,
                  width: double.infinity,
                  borderRadius: BorderRadius.zero,
                  backgroundColor: AppColors.cardBackgroundForIndex(index),
                  foregroundColor: AppColors.iconAccentForIndex(index),
                  caption: '[Photo ${index + 1} of $count]',
                );
              },
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          child: _CircleBackButton(onPressed: () => context.pop()),
        ),
        Positioned(
          bottom: AppSpacing.sm,
          right: AppSpacing.md,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: AppRadius.pillAll,
            ),
            child: Text(
              '${widget.photoIndex + 1} / $count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A circular, elevated back button used over the photo area.
class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
        ),
      ),
    );
  }
}

/// Horizontal row of selectable variant/color thumbnails.
class _VariantThumbnails extends StatelessWidget {
  const _VariantThumbnails({
    required this.variantLabels,
    required this.selectedIndex,
    required this.imageUrls,
  });

  final List<String> variantLabels;
  final int selectedIndex;
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.pagePadding,
        itemCount: variantLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final bool hasUrl = index < imageUrls.length;

          return GestureDetector(
            onTap: () =>
                context.read<ProductDetailsCubit>().selectVariant(index),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundForIndex(index),
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: hasUrl
                  ? Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                      errorBuilder: (ctx, err, stack) => Icon(
                        Icons.checkroom,
                        size: 22,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    )
                  : Icon(
                      Icons.checkroom,
                      size: 22,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
            ),
          );
        },
      ),
    );
  }
}

/// Indigo "Category · Type" line.
class _CategoryTypeLine extends StatelessWidget {
  const _CategoryTypeLine({
    required this.categoryLabel,
    required this.typeLabel,
  });

  final String categoryLabel;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$categoryLabel · $typeLabel',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Star + rating + sample ratings count.
class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        const Icon(Icons.star, size: 18, color: AppColors.rating),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toString(),
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '(126 ratings)',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Row of three small info chips: Price, Ready in, Payment.
class _InfoChipsRow extends StatelessWidget {
  const _InfoChipsRow({
    required this.priceInr,
    required this.readyInDays,
    required this.paymentLabel,
  });

  final int priceInr;
  final int readyInDays;
  final String paymentLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _InfoChip(
            icon: Icons.sell_outlined,
            label: 'Price',
            value: '₹$priceInr',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _InfoChip(
            icon: Icons.schedule,
            label: 'Ready in',
            value: '$readyInDays days',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _InfoChip(
            icon: Icons.payments_outlined,
            label: 'Payment',
            value: paymentLabel,
          ),
        ),
      ],
    );
  }
}

/// A single small info box used inside [_InfoChipsRow].
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.smd,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// A bold section heading like "About this style" / "Included".
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

/// A checklist of highlight points, each with a star icon.
class _HighlightsChecklist extends StatelessWidget {
  const _HighlightsChecklist({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.stars_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(item, style: textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// A checklist of included items, each with a green check icon.
class _IncludedChecklist extends StatelessWidget {
  const _IncludedChecklist({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: AppColors.statusReady,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(item, style: textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Pinned bottom bar with the stitching charge and the "Order now" CTA.
class _BottomOrderBar extends StatelessWidget {
  const _BottomOrderBar({
    required this.stitchingChargeInr,
    required this.product,
  });

  final int stitchingChargeInr;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.smd,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Stitching charge',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹$stitchingChargeInr',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 160,
                child: PrimaryButton(
                  label: 'Order now',
                  onPressed: () =>
                      context.pushNamed('orderDetails', extra: product),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
