import 'package:flutter/material.dart';

import '../../features/orders/domain/entities/order_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A small colored pill communicating an order's lifecycle status.
///
/// The default constructor maps an [OrderStatus] to a fixed label, foreground
/// color, and soft background tint using the `AppColors.status*` palette:
///
/// | status       | label         | foreground           | background             |
/// |--------------|---------------|----------------------|------------------------|
/// | `placed`     | "Ordered"     | `statusInProgress`   | `statusInProgressBg`   |
/// | `inProgress` | "In progress" | `statusInProgress`   | `statusInProgressBg`   |
/// | `ready`      | "Ready"       | `statusReady`        | `statusReadyBg`        |
/// | `completed`  | "Completed"   | `statusCompleted`    | `statusCompletedBg`    |
///
/// For the per-order text badges shown on the My orders cards (e.g.
/// "Stitching started", "Final touch-up"), use the [StatusBadge.text]
/// constructor to supply arbitrary label text with optional custom colors.
class StatusBadge extends StatelessWidget {
  /// Builds a badge from a known [OrderStatus].
  const StatusBadge({super.key, required this.status})
    : _label = null,
      _color = null,
      _background = null;

  /// Builds a badge from arbitrary [label] text.
  ///
  /// Defaults to the indigo "in progress" palette when [color] / [background]
  /// are omitted, matching the neutral informational badges in the mockups.
  const StatusBadge.text(
    String label, {
    super.key,
    Color? color,
    Color? background,
  }) : status = null,
       _label = label,
       _color = color,
       _background = background;

  /// The order status to render, or `null` when built via [StatusBadge.text].
  final OrderStatus? status;

  final String? _label;
  final Color? _color;
  final Color? _background;

  /// Resolved label text displayed in the pill.
  String get _resolvedLabel =>
      status != null ? _labelForStatus(status!) : _label!;

  /// Resolved foreground (text) color.
  ///
  /// Falls back to the indigo "in progress" palette for text badges that omit
  /// an explicit color.
  Color get _resolvedColor => status != null
      ? _colorForStatus(status!)
      : (_color ?? AppColors.statusInProgress);

  /// Resolved soft background tint.
  ///
  /// Falls back to the indigo "in progress" tint for text badges that omit an
  /// explicit background.
  Color get _resolvedBackground => status != null
      ? _backgroundForStatus(status!)
      : (_background ?? AppColors.statusInProgressBg);

  static String _labelForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Ordered';
      case OrderStatus.inProgress:
        return 'In progress';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
    }
  }

  static Color _colorForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.inProgress:
        return AppColors.statusInProgress;
      case OrderStatus.ready:
        return AppColors.statusReady;
      case OrderStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  static Color _backgroundForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.inProgress:
        return AppColors.statusInProgressBg;
      case OrderStatus.ready:
        return AppColors.statusReadyBg;
      case OrderStatus.completed:
        return AppColors.statusCompletedBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smd,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _resolvedBackground,
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        _resolvedLabel,
        style: TextStyle(
          color: _resolvedColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
