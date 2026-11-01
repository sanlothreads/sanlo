// Hide Material's own `StepState` so the domain entity's `StepState` resolves
// unambiguously.
import 'package:flutter/material.dart' hide StepState;

import 'package:sanlo/core/theme/app_colors.dart';
import 'package:sanlo/core/theme/app_spacing.dart';
import 'package:sanlo/features/orders/domain/entities/timeline_step.dart';

/// A vertical order-tracking timeline (matches the tracking mockup).
///
/// Each [TimelineStep] renders as a leading node connected by vertical
/// connector lines, alongside the step label and a subtitle:
///
/// - [StepState.done]: filled indigo node with a check, bold label, and the
///   step's timestamp.
/// - [StepState.current]: indigo ring node, bold label, and its timestamp.
/// - [StepState.pending]: grey outline node, muted label, and placeholder text.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.steps});

  /// The ordered steps to render, top to bottom.
  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            isFirst: i == 0,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

/// One row of the timeline: a node column (connector + node + connector) and
/// the label/subtitle text.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final TimelineStep step;
  final bool isFirst;
  final bool isLast;

  static const double _nodeSize = 24;
  static const double _railWidth = 2;
  static const double _rowMinHeight = 56;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDone = step.state == StepState.done;
    final bool isCurrent = step.state == StepState.current;
    final bool emphasized = isDone || isCurrent;

    // Connectors leading into a done/current node are "reached" (indigo); the
    // trailing connector is indigo only when this node is already done.
    final Color topConnector = (isDone || isCurrent)
        ? AppColors.primary
        : AppColors.border;
    final Color bottomConnector = isDone ? AppColors.primary : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Node + connectors column.
          SizedBox(
            width: _nodeSize,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: _railWidth,
                      color: isFirst ? Colors.transparent : topConnector,
                    ),
                  ),
                ),
                _TimelineNode(state: step.state),
                Expanded(
                  child: Center(
                    child: Container(
                      width: _railWidth,
                      color: isLast ? Colors.transparent : bottomConnector,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.smd),
          // Label + subtitle.
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _rowMinHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.label,
                      style: emphasized
                          ? textTheme.titleSmall
                          : textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _subtitle(),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Done/current steps show their timestamp; pending steps show placeholder
  /// text (current steps without a timestamp fall back to "In progress").
  String _subtitle() {
    if (step.state == StepState.pending) {
      return 'Pending';
    }
    final DateTime? ts = step.timestamp;
    if (ts == null) {
      return step.state == StepState.current ? 'In progress' : '';
    }
    return _formatTimestamp(ts);
  }

  static String _formatTimestamp(DateTime ts) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final String month = months[ts.month - 1];
    final int hour12 = ts.hour % 12 == 0 ? 12 : ts.hour % 12;
    final String minute = ts.minute.toString().padLeft(2, '0');
    final String period = ts.hour < 12 ? 'AM' : 'PM';
    return '$month ${ts.day}, $hour12:$minute $period';
  }
}

/// The circular leading node whose appearance encodes the [StepState].
class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.state});

  final StepState state;

  static const double _size = _TimelineRow._nodeSize;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case StepState.done:
        return Container(
          width: _size,
          height: _size,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: AppColors.onPrimary,
          ),
        );
      case StepState.current:
        return Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case StepState.pending:
        return Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        );
    }
  }
}
