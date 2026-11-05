import '../../domain/entities/admin_order.dart';
import '../../domain/entities/order_stage.dart';

/// Data-layer DTO for [AdminOrder]. Enums are serialised by `name`.
class AdminOrderModel {
  const AdminOrderModel({
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

  final String id;
  final String item;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final DateTime placedDate;
  final DateTime dueDate;
  final int amountAtShopInr;
  final String stage;
  final String measurementState;
  final String? measurementNote;

  AdminOrder toEntity() {
    return AdminOrder(
      id: id,
      item: item,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      placedDate: placedDate,
      dueDate: dueDate,
      amountAtShopInr: amountAtShopInr,
      stage: OrderStage.values.byName(stage),
      measurementState: MeasurementState.values.byName(measurementState),
      measurementNote: measurementNote,
    );
  }
}
