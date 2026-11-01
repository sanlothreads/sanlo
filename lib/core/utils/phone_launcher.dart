import 'package:url_launcher/url_launcher.dart';

/// Signature for a function that checks whether a [Uri] can be launched.
typedef CanLaunchUrlFn = Future<bool> Function(Uri uri);

/// Signature for a function that launches a [Uri].
typedef LaunchUrlFn = Future<bool> Function(Uri uri);

/// Thin wrapper around `url_launcher` for placing phone calls via a `tel:`
/// URI.
///
/// The dialer is only invoked when the platform reports that the `tel:` URI
/// can be launched. When it cannot (for example on a device without a phone
/// app), [call] is a no-op and returns `false` instead of throwing, leaving
/// the caller's screen unchanged.
///
/// The underlying `canLaunchUrl` / `launchUrl` functions can be overridden via
/// the optional [canLaunchUrlFn] and [launchUrlFn] parameters so the behaviour
/// can be unit tested without touching the real platform channels.
class PhoneLauncher {
  const PhoneLauncher._();

  /// Attempts to open the device dialer for [number] using a `tel:` URI.
  ///
  /// Returns `true` when the dialer was launched, and `false` when the
  /// platform cannot handle the `tel:` action (the call is then a no-op).
  static Future<bool> call(
    String number, {
    CanLaunchUrlFn? canLaunchUrlFn,
    LaunchUrlFn? launchUrlFn,
  }) async {
    final uri = Uri(scheme: 'tel', path: number);
    final canLaunchFn = canLaunchUrlFn ?? canLaunchUrl;
    final launchFn = launchUrlFn ?? launchUrl;

    if (await canLaunchFn(uri)) {
      return launchFn(uri);
    }
    return false;
  }
}
