import 'package:flutter/widgets.dart';

import '../theme/app_spacing.dart';

/// Centers its [child] and caps its width at [maxWidth] (default
/// [AppSpacing.maxContentWidth]).
///
/// This is the app-wide responsive wrapper: on a phone the child fills the
/// available width (the constraint is wider than the screen, so it's a no-op),
/// while on wide web/desktop windows the content stays a comfortable, readable
/// width and is centered instead of stretching edge-to-edge.
///
/// Wrap a screen's body (the direct child of `Scaffold.body`) with it:
///
/// ```dart
/// Scaffold(body: SafeArea(child: ResponsiveCenter(child: ...)))
/// ```
///
/// It takes the full available height, so scroll views and column layouts lay
/// out exactly as before — only the horizontal extent is constrained.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  /// The content to center and width-constrain.
  final Widget child;

  /// The maximum width the [child] may occupy.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
