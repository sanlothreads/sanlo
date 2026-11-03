import 'package:equatable/equatable.dart';

/// Body measurements captured in step 2 of the order flow.
///
/// All numeric measurements are in inches. When [knowsMeasurements] is `false`
/// ("Not sure"), the individual fields are typically left `null` and the shop
/// will take measurements in person.
class MeasurementSet extends Equatable {
  const MeasurementSet({
    required this.knowsMeasurements,
    this.bust,
    this.waist,
    this.shoulder,
    this.sleeveLength,
    this.armhole,
    this.blouseLength,
    this.designNotes,
  });

  /// `false` => "Not sure", measurement fields are skipped.
  final bool knowsMeasurements;

  /// Bust measurement in inches.
  final double? bust;

  /// Waist measurement in inches.
  final double? waist;

  /// Shoulder measurement in inches.
  final double? shoulder;

  /// Sleeve length in inches.
  final double? sleeveLength;

  /// Armhole measurement in inches.
  final double? armhole;

  /// Blouse length in inches.
  final double? blouseLength;

  /// Optional free-text design notes.
  final String? designNotes;

  /// Returns a copy of this set with the given fields replaced.
  MeasurementSet copyWith({
    bool? knowsMeasurements,
    double? bust,
    double? waist,
    double? shoulder,
    double? sleeveLength,
    double? armhole,
    double? blouseLength,
    String? designNotes,
  }) {
    return MeasurementSet(
      knowsMeasurements: knowsMeasurements ?? this.knowsMeasurements,
      bust: bust ?? this.bust,
      waist: waist ?? this.waist,
      shoulder: shoulder ?? this.shoulder,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      armhole: armhole ?? this.armhole,
      blouseLength: blouseLength ?? this.blouseLength,
      designNotes: designNotes ?? this.designNotes,
    );
  }

  @override
  List<Object?> get props => [
    knowsMeasurements,
    bust,
    waist,
    shoulder,
    sleeveLength,
    armhole,
    blouseLength,
    designNotes,
  ];
}
