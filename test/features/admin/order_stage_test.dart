import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/features/admin/domain/entities/order_stage.dart';

void main() {
  group('OrderStage', () {
    test('labels match the design', () {
      expect(OrderStage.ordered.label, 'Ordered');
      expect(OrderStage.measurementDone.label, 'Measurement done');
      expect(OrderStage.stitchingStarted.label, 'Stitching started');
      expect(OrderStage.stitchingFinished.label, 'Stitching finished');
      expect(OrderStage.finalTouchUp.label, 'Final touch-up');
      expect(OrderStage.allSet.label, 'All set');
    });

    test('next walks forward and stops at allSet', () {
      expect(OrderStage.ordered.next, OrderStage.measurementDone);
      expect(OrderStage.finalTouchUp.next, OrderStage.allSet);
      expect(OrderStage.allSet.next, isNull);
      expect(OrderStage.allSet.isFinal, isTrue);
      expect(OrderStage.ordered.isFinal, isFalse);
    });

    test('advance action labels', () {
      expect(OrderStage.ordered.advanceActionLabel,
          'Mark as "Measurement done"');
      expect(OrderStage.finalTouchUp.advanceActionLabel, 'Mark as "All set"');
      expect(OrderStage.allSet.advanceActionLabel, isNull);
      expect(OrderStage.ordered.advanceActionLabelShort,
          'Mark "Measurement done"');
    });
  });
}
