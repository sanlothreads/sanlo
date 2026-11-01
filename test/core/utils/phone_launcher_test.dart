import 'package:flutter_test/flutter_test.dart';
import 'package:sanlo/core/utils/phone_launcher.dart';

void main() {
  group('PhoneLauncher.call', () {
    test(
      'builds a tel: URI from the number and launches it when possible',
      () async {
        Uri? checkedUri;
        Uri? launchedUri;

        final result = await PhoneLauncher.call(
          '+919000000000',
          canLaunchUrlFn: (uri) async {
            checkedUri = uri;
            return true;
          },
          launchUrlFn: (uri) async {
            launchedUri = uri;
            return true;
          },
        );

        expect(result, isTrue);
        expect(checkedUri, Uri(scheme: 'tel', path: '+919000000000'));
        expect(launchedUri, Uri(scheme: 'tel', path: '+919000000000'));
      },
    );

    test('no-ops and returns false when the dialer is unavailable', () async {
      var launchCalled = false;

      final result = await PhoneLauncher.call(
        '+919000000000',
        canLaunchUrlFn: (_) async => false,
        launchUrlFn: (_) async {
          launchCalled = true;
          return true;
        },
      );

      expect(result, isFalse);
      expect(launchCalled, isFalse);
    });

    test('returns the launch result when launching fails', () async {
      final result = await PhoneLauncher.call(
        '+919000000000',
        canLaunchUrlFn: (_) async => true,
        launchUrlFn: (_) async => false,
      );

      expect(result, isFalse);
    });
  });
}
