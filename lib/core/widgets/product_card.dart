import 'package:flutter/material.dart';

import 'package:sanlo/core/theme/app_colors.dart';
import 'package:sanlo/core/theme/app_spacing.dart';
import 'package:sanlo/core/widgets/image_placeholder.dart';
import 'package:sanlo/features/catalog/domain/entities/category.dart';
import 'package:sanlo/features/catalog/domain/entities/product.dart';

/// A single product tile for the 2-column Home catalog grid.
///
/// Mirrors the Home mockup: a pastel [ImagePlaceholder] image area on top,
/// then the category label (e.g. "Women"), the bold product name, a star
/// rating row ("★ 4.8 · 5 days"), and the bold price ("₹650"). The whole card
/// is tappable via [onTap].
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  /// The product to render.
  final Product product;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Human-readable label for a product's [CategoryKind].
  ///
  /// [CategoryKind.all] is the "no filter" sentinel and is never a product's
  /// own category, so it falls back to an empty label.
  static String _categoryLabel(CategoryKind kind) {
    switch (kind) {
      case CategoryKind.women:
        return 'Women';
      case CategoryKind.men:
        return 'Men';
      case CategoryKind.kids:
        return 'Kids';
      case CategoryKind.all:
        return '';
    }
  }

  /// Picks a stable pastel tint for the image area derived from the product's
  /// category so the grid shows a pleasant, repeatable spread of colors.
  Color _cardBackground() {
    switch (product.category) {
      case CategoryKind.women:
        return AppColors.cardLavender;
      case CategoryKind.men:
        return AppColors.cardMint;
      case CategoryKind.kids:
        return AppColors.cardPink;
      case CategoryKind.all:
        return AppColors.cardPeach;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String category = _categoryLabel(product.category);

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — pastel tinted placeholder filling available top space.
            Expanded(
              child: ImagePlaceholder(
                width: double.infinity,
                backgroundColor: _cardBackground(),
                foregroundColor: AppColors.primary,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.smd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category.isNotEmpty) ...[
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _RatingRow(
                    rating: product.rating,
                    readyInDays: product.readyInDays,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '₹${product.priceInr}',
                    style: textTheme.titleMedium,
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

/// The "★ {rating} · {readyInDays} days" metadata row.
class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.readyInDays});

  final double rating;
  final int readyInDays;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? style =
        textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.rating),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            '$rating · $readyInDays days',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
