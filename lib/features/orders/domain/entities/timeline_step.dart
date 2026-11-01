import 'package:equatable/equatable.dart';

/// The ordered stages an order passes through on the tracking timeline.
enum TimelineStage {
  orderPlaced,
  measurementDone,
  stitchingStarted,
  stitchingFinished,
  finalTouchUp,
  allSet,
}

/// Visual/logical state of a single [TimelineStep].
///
/// - [done]: the stage has been completed.
/// - [current]: the stage currently in progress (at most one per timeline).
/// - [pending]: the stage has not been reached yet.
enum StepState { done, current, pending }

/// A single node on the order tracking timeline.
class TimelineStep extends Equatable {
  const TimelineStep({
    required this.stage,
    required this.label,
    required this.state,
    this.timestamp,
  });

  /// Which stage this step represents.
  final TimelineStage stage;

  /// Human-readable label, e.g. "Order placed", "Measurement done".
  final String label;

  /// Whether this step is done, current, or pending.
  final StepState state;

  /// When the step occurred; `null` while the step is still pending.
  final DateTime? timestamp;

  @override
  List<Object?> get props => [stage, label, state, timestamp];
}
