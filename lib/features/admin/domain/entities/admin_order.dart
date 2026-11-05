import 'package:equatable/equatable.dart';

import 'order_stage.dart';

/// Whether the customer entered measurements online or will be measured at the
/// shop.
enum MeasurementState { entered, notSure }

/// Display helpers for [MeasurementState].
extension MeasurementStateX on MeasurementState {
  String get label =>
      this == MeasurementState.entered ? 'Entered' : 'Not sure';
}

/// An order as seen by the admin, carrying the full six-stage lifecycle plus
/// the customer and measurement context shown on the Orders detail panel.
class AdminOrder extends Equatable {
  const AdminOrder({
    required this.id,
    required this.item,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.placedDate,
    required this.dueDate,
    required this.amountAtShopInr,
    required this.stage,
    required this.measurementState,
    this.measurementNote,
  });

  /// Order identifier, e.g. "SN-1048" (displayed as "#SN-1048").
  final String id;

  /// Item name, e.g. "Formal Shirt".
  final String item;

  final String customerName;
  final String customerPhone;
  final String customerAddress;

  /// When the order was placed.
  final DateTime placedDate;

  /// Expected ready / due date.
  final DateTime dueDate;

  /// Amount payable at the shop (INR).
  final int amountAtShopInr;

  /// Current lifecycle stage.
  final OrderStage stage;

  /// Whether measurements were entered online or will be taken at the shop.
  final MeasurementState measurementState;

  /// Optional free-text note shown in the measurements box.
  final String? measurementNote;

  /// Returns a copy with the given fields replaced.
  AdminOrder copyWith({OrderStage? stage}) {
    return AdminOrder(
      id: id,
      item: item,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      placedDate: placedDate,
      dueDate: dueDate,
      amountAtShopInr: amountAtShopInr,
      stage: stage ?? this.stage,
      measurementState: measurementState,
      measurementNote: measurementNote,
    );
  }

  @override
  List<Object?> get props => [
    id,
    item,
    customerName,
    customerPhone,
    customerAddress,
    placedDate,
    dueDate,
    amountAtShopInr,
    stage,
    measurementState,
    measurementNote,
  ];
}
