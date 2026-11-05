import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The admin-facing stitching lifecycle of an order.
///
/// This is intentionally separate from the customer-facing
/// `OrderStatus` enum: the admin workflow tracks six fine-grained stages while
/// the customer side only needs the coarse placed/inProgress/ready/completed
/// view. Keeping them apart means the customer flow is untouched by admin work.
///
/// The values are ordered from first to last; [OrderStageX.next] walks this
/// order and returns `null` once [allSet] (the terminal stage) is reached.
enum OrderStage {
  ordered,
  measurementDone,
  stitchingStarted,
  stitchingFinished,
  finalTouchUp,
  allSet,
}

/// Display and lifecycle helpers for [OrderStage].
extension OrderStageX on OrderStage {
  /// Human-readable label shown on badges, steppers, and tables.
  String get label {
    switch (this) {
      case OrderStage.ordered:
        return 'Ordered';
      case OrderStage.measurementDone:
        return 'Measurement done';
      case OrderStage.stitchingStarted:
        return 'Stitching started';
      case OrderStage.stitchingFinished:
        return 'Stitching finished';
      case OrderStage.finalTouchUp:
        return 'Final touch-up';
      case OrderStage.allSet:
        return 'All set';
    }
  }

  /// The following stage in the lifecycle, or `null` when already [allSet].
  OrderStage? get next {
    final List<OrderStage> values = OrderStage.values;
    final int i = index;
    return i < values.length - 1 ? values[i + 1] : null;
  }

  /// Whether this is the terminal stage (no further advancement possible).
  bool get isFinal => next == null;

  /// Label for the primary button that advances the order to [next], e.g.
  /// `Mark as "Measurement done"`. `null` when the stage is terminal.
  String? get advanceActionLabel {
    final OrderStage? n = next;
    return n == null ? null : 'Mark as "${n.label}"';
  }

  /// Short "Mark ..." label used on the condensed mobile action cards, e.g.
  /// `Mark "Measurement done"`. `null` when the stage is terminal.
  String? get advanceActionLabelShort {
    final OrderStage? n = next;
    return n == null ? null : 'Mark "${n.label}"';
  }

  /// Foreground color for this stage, mapped to the app status palette.
  ///
  /// In-flight stages use the brand crimson; the terminal [allSet] stage uses
  /// the green "ready/done" color, matching the existing status conventions.
  Color get color =>
      this == OrderStage.allSet
          ? AppColors.statusReady
          : AppColors.statusInProgress;

  /// Soft background tint paired with [color].
  Color get bgColor =>
      this == OrderStage.allSet
          ? AppColors.statusReadyBg
          : AppColors.statusInProgressBg;
}
