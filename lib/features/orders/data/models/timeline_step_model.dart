import '../../domain/entities/timeline_step.dart';

/// Data-layer DTO for [TimelineStep].
///
/// Serialises [TimelineStage] and [StepState] as their enum names and
/// [timestamp] as an ISO-8601 string (`null` while pending).
class TimelineStepModel {
  const TimelineStepModel({
    required this.stage,
    required this.label,
    required this.state,
    this.timestamp,
  });

  final String stage;
  final String label;
  final String state;
  final String? timestamp;

  factory TimelineStepModel.fromJson(Map<String, dynamic> json) {
    return TimelineStepModel(
      stage: json['stage'] as String,
      label: json['label'] as String,
      state: json['state'] as String,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'label': label,
      'state': state,
      'timestamp': timestamp,
    };
  }

  factory TimelineStepModel.fromEntity(TimelineStep entity) {
    return TimelineStepModel(
      stage: entity.stage.name,
      label: entity.label,
      state: entity.state.name,
      timestamp: entity.timestamp?.toIso8601String(),
    );
  }

  TimelineStep toEntity() {
    return TimelineStep(
      stage: TimelineStage.values.byName(stage),
      label: label,
      state: StepState.values.byName(state),
      timestamp: timestamp == null ? null : DateTime.parse(timestamp!),
    );
  }
}
