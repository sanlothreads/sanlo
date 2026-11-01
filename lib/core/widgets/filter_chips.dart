import 'package:flutter/material.dart';

import 'package:sanlo/core/theme/app_spacing.dart';
import 'package:sanlo/features/catalog/domain/entities/category.dart';

/// A horizontally scrollable row of selectable category pills
/// (All / Women / Men / Kids) shown on the Home screen.
///
/// Exactly one chip is selected at a time; tapping a chip reports its
/// [CategoryKind] through [onSelected]. The selected chip renders indigo and
/// the rest render on the muted surface — both driven by the app's
/// [ChipThemeData] (see `AppTheme`).
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  /// The categories to render as chips, in display order.
  final List<Category> categories;

  /// The currently selected category kind.
  final CategoryKind selected;

  /// Called with the tapped category's kind.
  final ValueChanged<CategoryKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.pagePadding,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final Category category = categories[index];
          final bool isSelected = category.kind == selected;

          return Center(
            child: ChoiceChip(
              label: Text(category.label),
              selected: isSelected,
              onSelected: (_) => onSelected(category.kind),
            ),
          );
        },
      ),
    );
  }
}
