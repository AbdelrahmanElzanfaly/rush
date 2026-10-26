import 'package:flutter/widgets.dart';

import '../core/rush_device_type.dart';
import '../core/rush_screen_map.dart';
import '../rush_setup.dart';

/// Signature for [RushBuilder.builder].
///
/// [type] is the layout slot to render — the detected device class with any
/// [RushScreenMap] already applied — and [constraints] are the real
/// constraints handed down by the parent, so you can mix coarse branching with
/// exact measurements.
typedef RushWidgetBuilder = Widget Function(
  BuildContext context,
  RushDeviceType type,
  BoxConstraints constraints,
);

/// Rebuilds its subtree with the current [RushDeviceType] whenever the
/// available width crosses a breakpoint.
///
/// Use this when the branches share state or differ only slightly — a column
/// count, a padding value, an axis — and spelling out three whole widgets
/// would duplicate code:
///
/// ```dart
/// RushBuilder(
///   builder: (context, type, constraints) => GridView.count(
///     crossAxisCount: type.pick(mobile: 1, tablet: 2, desktop: 4),
///     children: tiles,
///   ),
/// )
/// ```
///
/// The `type` you receive is the layout slot after the configured
/// [RushScreenMap] has been applied, so a builder honours a remap the same way
/// `RushWidget` does. Breakpoints and remapping come from `RushSetup`; set
/// them once at startup with `RushSetup.init`.
///
/// By default the screen class is computed from the **incoming constraints**,
/// not the window, so a `RushBuilder` inside a narrow sidebar correctly sees
/// itself as mobile even on a desktop. Set [useWindowWidth] to `true` to key
/// off the window instead. If the incoming constraints are horizontally
/// unbounded — inside a [Row], a horizontal [ListView] or an unconstrained
/// [SingleChildScrollView] — Rush falls back to the window width rather than
/// classifying an infinite width.
class RushBuilder extends StatelessWidget {
  /// Creates a builder that reacts to breakpoint changes.
  const RushBuilder({
    super.key,
    required this.builder,
    this.useWindowWidth = false,
  });

  /// Called with the layout slot to render and the incoming constraints.
  final RushWidgetBuilder builder;

  /// Measure the whole window instead of the incoming constraints.
  ///
  /// Defaults to `false`.
  final bool useWindowWidth;

  @override
  Widget build(BuildContext context) {
    final config = RushSetup.config;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = resolveWidth(
          context,
          constraints,
          useWindowWidth: useWindowWidth,
        );
        return builder(context, config.slotForWidth(width), constraints);
      },
    );
  }

  /// The width Rush measures for [constraints], in logical pixels.
  ///
  /// Returns the window width when [useWindowWidth] is set or when
  /// `constraints.maxWidth` is unbounded; otherwise returns
  /// `constraints.maxWidth`. Falls back to `0` — that is, to
  /// [RushDeviceType.mobile] — if there is no [MediaQuery] ancestor.
  ///
  /// Exposed for tests and for widgets composing on top of Rush.
  @visibleForTesting
  static double resolveWidth(
    BuildContext context,
    BoxConstraints constraints, {
    bool useWindowWidth = false,
  }) {
    if (!useWindowWidth && constraints.maxWidth.isFinite) {
      return constraints.maxWidth;
    }
    return MediaQuery.maybeSizeOf(context)?.width ?? 0;
  }
}
