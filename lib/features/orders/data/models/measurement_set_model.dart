import '../../domain/entities/measurement_set.dart';

/// Data-layer DTO for [MeasurementSet]. All numeric fields are in inches.
class MeasurementSetModel {
  const MeasurementSetModel({
    required this.knowsMeasurements,
    this.bust,
    this.waist,
    this.shoulder,
    this.sleeveLength,
    this.armhole,
    this.blouseLength,
    this.designNotes,
  });

  final bool knowsMeasurements;
  final double? bust;
  final double? waist;
  final double? shoulder;
  final double? sleeveLength;
  final double? armhole;
  final double? blouseLength;
  final String? designNotes;

  factory MeasurementSetModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return MeasurementSetModel(
      knowsMeasurements: json['knowsMeasurements'] as bool,
      bust: toDouble(json['bust']),
      waist: toDouble(json['waist']),
      shoulder: toDouble(json['shoulder']),
      sleeveLength: toDouble(json['sleeveLength']),
      armhole: toDouble(json['armhole']),
      blouseLength: toDouble(json['blouseLength']),
      designNotes: json['designNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'knowsMeasurements': knowsMeasurements,
      'bust': bust,
      'waist': waist,
      'shoulder': shoulder,
      'sleeveLength': sleeveLength,
      'armhole': armhole,
      'blouseLength': blouseLength,
      'designNotes': designNotes,
    };
  }

  factory MeasurementSetModel.fromEntity(MeasurementSet entity) {
    return MeasurementSetModel(
      knowsMeasurements: entity.knowsMeasurements,
      bust: entity.bust,
      waist: entity.waist,
      shoulder: entity.shoulder,
      sleeveLength: entity.sleeveLength,
      armhole: entity.armhole,
      blouseLength: entity.blouseLength,
      designNotes: entity.designNotes,
    );
  }

  MeasurementSet toEntity() {
    return MeasurementSet(
      knowsMeasurements: knowsMeasurements,
      bust: bust,
      waist: waist,
      shoulder: shoulder,
      sleeveLength: sleeveLength,
      armhole: armhole,
      blouseLength: blouseLength,
      designNotes: designNotes,
    );
  }
}
