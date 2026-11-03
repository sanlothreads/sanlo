import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A reusable rounded container used to group related content into a labelled
/// block, such as the "Your details" and "Measurements" cards on the order
/// review screen.
///
/// It draws a white surface with a large [AppRadius.lg] corner radius and the
/// standard [AppSpacing.cardPadding] inset. When [title] is provided it renders
/// a heading row above the [child]; an optional [trailing] widget (for example
/// an "Edit" action) sits at the end of that row.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.backgroundColor,
    this.padding,
  });

  /// The body of the card. Required.
  final Widget child;

  /// Optional heading rendered above [child]. When null, no heading row is
  /// shown (and [trailing] is ignored).
  final String? title;

  /// Optional widget placed at the end of the heading row, e.g. an "Edit"
  /// [TextButton]. Only shown when [title] is non-null.
  final Widget? trailing;

  /// Surface fill. Defaults to [AppColors.surface] (white).
  final Color? backgroundColor;

  /// Inset around the card content. Defaults to [AppSpacing.cardPadding].
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? title = this.title;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: AppRadius.lgAll,
      ),
      padding: padding ?? AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(title, style: textTheme.titleMedium)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.smd),
          ],
          child,
        ],
      ),
    );
  }
}
