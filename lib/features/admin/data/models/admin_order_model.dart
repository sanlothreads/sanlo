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

  /// Safely parses raw Firestore JSON document data into an [AdminOrderModel].
  factory AdminOrderModel.fromMap(Map<String, dynamic> map, String docId) {
    final String cleanId = (map['id'] as String? ?? docId).trim();

    // Item/Product name
    String itemName = 'Stitching Order';
    final dynamic productData = map['product'];
    if (productData is Map) {
      final Map<String, dynamic> prodMap =
          Map<String, dynamic>.from(productData);
      itemName = (prodMap['name'] as String? ??
              prodMap['typeLabel'] as String? ??
              '')
          .trim();
    }
    if (itemName.isEmpty && map['item'] is String) {
      itemName = (map['item'] as String).trim();
    }
    if (itemName.isEmpty) {
      itemName = 'Stitching Order';
    }

    // Customer details
    String customerName = 'Customer';
    String customerPhone = '—';
    String customerAddress = 'Shop Visit';

    final dynamic detailsData = map['details'];
    if (detailsData is Map) {
      final Map<String, dynamic> detMap =
          Map<String, dynamic>.from(detailsData);
      customerName = (detMap['fullName'] as String? ??
              detMap['name'] as String? ??
              '')
          .trim();
      customerPhone = (detMap['phone'] as String? ??
              detMap['mobile'] as String? ??
              '')
          .trim();
      customerAddress = (detMap['deliveryAddress'] as String? ??
              detMap['address'] as String? ??
              '')
          .trim();
    }

    if (customerName.isEmpty && map['customerName'] is String) {
      customerName = (map['customerName'] as String).trim();
    }
    if (customerName.isEmpty) customerName = 'Customer';

    if ((customerPhone.isEmpty || customerPhone == '—') &&
        map['customerPhone'] is String) {
      customerPhone = (map['customerPhone'] as String).trim();
    }
    if (customerPhone.isEmpty) customerPhone = '—';

    if ((customerAddress.isEmpty || customerAddress == 'Shop Visit') &&
        map['customerAddress'] is String) {
      customerAddress = (map['customerAddress'] as String).trim();
    }
    if (customerAddress.isEmpty) customerAddress = 'Shop Visit';

    // Dates
    DateTime placed = _parseDateTime(map['placedDate']) ?? DateTime.now();
    DateTime due = _parseDateTime(map['expectedReady']) ??
        _parseDateTime(map['dueDate']) ??
        placed.add(const Duration(days: 5));

    // Amount
    final int amount = (map['amountAtShopInr'] as num?)?.toInt() ??
        (productData is Map
            ? (productData['priceInr'] as num?)?.toInt() ?? 0
            : 0);

    // Stage
    final String rawStage =
        (map['stage'] as String? ?? map['status'] as String? ?? 'ordered');
    final String normalizedStage = _normalizeStage(rawStage);

    // Measurement state & note
    String normMeasurementState = 'entered';
    String? note = map['measurementNote'] as String?;

    final dynamic measurementsData = map['measurements'];
    if (measurementsData is Map) {
      final Map<String, dynamic> mData =
          Map<String, dynamic>.from(measurementsData);
      final String opt = (mData['option'] as String? ??
              mData['type'] as String? ??
              '')
          .toLowerCase();
      if (opt.contains('notsure') || opt.contains('atshop')) {
        normMeasurementState = 'notSure';
        note ??=
            'Customer chose "Not sure" - take measurements when they visit the shop.';
      } else {
        normMeasurementState = 'entered';
        if (note == null || note.isEmpty) {
          final List<String> parts = <String>[];
          if (mData['bustInches'] != null) {
            parts.add('Bust: ${mData['bustInches']}"');
          }
          if (mData['waistInches'] != null) {
            parts.add('Waist: ${mData['waistInches']}"');
          }
          if (mData['shoulderInches'] != null) {
            parts.add('Shoulder: ${mData['shoulderInches']}"');
          }
          if (mData['lengthInches'] != null) {
            parts.add('Length: ${mData['lengthInches']}"');
          }
          if (parts.isNotEmpty) {
            note = parts.join(', ');
          }
        }
      }
    } else {
      final String mState =
          (map['measurementState'] as String? ?? '').toLowerCase();
      if (mState.contains('notsure') || mState.contains('atshop')) {
        normMeasurementState = 'notSure';
      }
    }

    return AdminOrderModel(
      id: cleanId,
      item: itemName,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      placedDate: placed,
      dueDate: due,
      amountAtShopInr: amount,
      stage: normalizedStage,
      measurementState: normMeasurementState,
      measurementNote: note,
    );
  }

  factory AdminOrderModel.fromEntity(AdminOrder entity) {
    return AdminOrderModel(
      id: entity.id,
      item: entity.item,
      customerName: entity.customerName,
      customerPhone: entity.customerPhone,
      customerAddress: entity.customerAddress,
      placedDate: entity.placedDate,
      dueDate: entity.dueDate,
      amountAtShopInr: entity.amountAtShopInr,
      stage: entity.stage.name,
      measurementState: entity.measurementState.name,
      measurementNote: entity.measurementNote,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'item': item,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'placedDate': placedDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'amountAtShopInr': amountAtShopInr,
      'stage': stage,
      'measurementState': measurementState,
      if (measurementNote != null) 'measurementNote': measurementNote,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic timestamp = value;
      return timestamp.toDate() as DateTime;
    } catch (_) {}
    return null;
  }

  static String _normalizeStage(String input) {
    final String lower = input.trim().toLowerCase();
    if (lower == 'ordered' || lower == 'placed' || lower == 'draft') {
      return 'ordered';
    }
    if (lower == 'measurementdone' ||
        lower == 'measured' ||
        lower == 'measurement_done') {
      return 'measurementDone';
    }
    if (lower == 'stitchingstarted' ||
        lower == 'stitching_started' ||
        lower == 'stitching') {
      return 'stitchingStarted';
    }
    if (lower == 'stitchingfinished' ||
        lower == 'stitching_finished' ||
        lower == 'stitched') {
      return 'stitchingFinished';
    }
    if (lower == 'finaltouchup' ||
        lower == 'final_touchup' ||
        lower == 'touchup') {
      return 'finalTouchUp';
    }
    if (lower == 'allset' ||
        lower == 'all_set' ||
        lower == 'ready' ||
        lower == 'completed') {
      return 'allSet';
    }
    return 'ordered';
  }

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
