import 'package:flutter/widgets.dart';

import 'core/rush_breakpoints.dart';
import 'core/rush_config.dart';
import 'core/rush_device_type.dart';
import 'core/rush_screen_map.dart';

/// Holds the app-wide [RushConfig] and answers questions against it.
///
/// This class is deliberately thin. The rules live on [RushConfig] — which
/// widths mean what, which slot a size renders, how a value is picked — and
/// `RushSetup` is only the place the app keeps one of them.
///
/// Calling [init] is **optional**. Rush ships with [RushConfig.standard], so
/// a widget built before any call to [init] renders correctly instead of
/// throwing.
///
/// ```dart
/// void main() {
///   RushSetup.init(const RushConfig(
///     breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
///     // No tablet design yet — tablet screens use the desktop layout.
///     screens: RushScreenMap(tablet: RushDeviceType.desktop),
///   ));
///   runApp(const MyApp());
/// }
/// ```
///
/// [init] is idempotent and may be called any number of times, including
/// after a hot restart or between tests. To change one knob and keep the
/// other, pass a [RushConfig.copyWith] of the current [config].
///
/// The configuration is app-wide by design: `RushWidget` and `RushBuilder`
/// read it here at build time, so there is nothing to pass down the tree and
/// nothing to keep in sync. Note that widgets already on screen do not
/// rebuild by themselves when this changes — call [init] before `runApp`, or
/// rebuild the affected subtree yourself.
abstract final class RushSetup {
  static RushConfig _config = RushConfig.standard;

  // -----------------------------------------------------------------------
  // Reading the configuration
  // -----------------------------------------------------------------------

  /// The configuration currently in effect. Never null.
  static RushConfig get config => _config;

  /// The breakpoints currently in effect.
  ///
  /// Shorthand for `RushSetup.config.breakpoints`.
  static RushBreakpoints get breakpoints => _config.breakpoints;

  /// The screen-to-slot mapping currently in effect.
  ///
  /// Shorthand for `RushSetup.config.screens`. Defaults to
  /// [RushScreenMap.identity], where every device class renders its own
  /// layout.
  static RushScreenMap get screens => _config.screens;

  /// The inclusive lower bound of [RushDeviceType.tablet], in logical pixels.
  static double get startTabletSize => _config.breakpoints.tablet;

  /// The inclusive lower bound of [RushDeviceType.desktop], in logical pixels.
  static double get startDesktopSize => _config.breakpoints.desktop;

  // -----------------------------------------------------------------------
  // Changing the configuration
  // -----------------------------------------------------------------------

  /// Sets the app-wide configuration.
  ///
  /// ```dart
  /// RushSetup.init(const RushConfig(
  ///   breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
  /// ));
  /// ```
  ///
  /// To change one knob and keep the other, copy the current one:
  ///
  /// ```dart
  /// RushSetup.init(RushSetup.config.copyWith(
  ///   screens: RushScreenMap.alwaysMobile,
  /// ));
  /// ```
  ///
  /// Called with no argument it restores the defaults, exactly like [reset].
  ///
  /// Throws an [ArgumentError] if [config] is not usable, leaving the
  /// previous configuration untouched. Safe to call more than once.
  static void init([RushConfig config = RushConfig.standard]) {
    config.validate();
    _config = config;
  }

  /// Restores [RushConfig.standard].
  ///
  /// Mostly useful in `tearDown` so one test's configuration cannot leak into
  /// the next.
  static void reset() => _config = RushConfig.standard;

  // -----------------------------------------------------------------------
  // Classifying a width
  // -----------------------------------------------------------------------

  /// The layout slot [width] should render.
  ///
  /// Shorthand for `RushSetup.config.slotForWidth(width)`. Use
  /// [detectedTypeOf] for the raw classification, before [screens] is
  /// applied.
  static RushDeviceType typeOf(double width) => _config.slotForWidth(width);

  /// The raw device class of [width], ignoring [screens].
  ///
  /// Shorthand for `RushSetup.config.detectedForWidth(width)`.
  static RushDeviceType detectedTypeOf(double width) =>
      _config.detectedForWidth(width);

  /// The layout slot the current window should render.
  ///
  /// This reads `MediaQuery.sizeOf(context).width` — the width of the whole
  /// window, not of the enclosing box. Inside a panel, sidebar or dialog you
  /// usually want `RushBuilder` instead, which measures actual constraints.
  ///
  /// Establishes a dependency on the ambient [MediaQuery], so the caller
  /// rebuilds when the window is resized.
  static RushDeviceType of(BuildContext context) =>
      typeOf(MediaQuery.sizeOf(context).width);

  /// The raw device class of the current window, ignoring [screens].
  static RushDeviceType detectedOf(BuildContext context) =>
      detectedTypeOf(MediaQuery.sizeOf(context).width);

  // -----------------------------------------------------------------------
  // Picking a value
  // -----------------------------------------------------------------------

  /// Picks one of three values for the given [width].
  ///
  /// Shorthand for `RushSetup.config.resolve(...)`, which classifies [width]
  /// and then picks. Honours [screens], so a remapped type picks the value it
  /// renders as.
  ///
  /// ```dart
  /// final columns =
  ///     RushSetup.resolve(width: 900, mobile: 1, tablet: 2, desktop: 4);
  /// ```
  static T resolve<T>({
    required double width,
    required T mobile,
    required T tablet,
    required T desktop,
  }) =>
      _config.resolve(
        width: width,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );

  /// Picks one of three values for the given [type].
  ///
  /// Shorthand for [RushDeviceType.pick] on a type you already hold — for
  /// example one handed to you by `RushBuilder`, which has already applied
  /// [screens].
  static T resolveFor<T>({
    required RushDeviceType type,
    required T mobile,
    required T tablet,
    required T desktop,
  }) =>
      type.pick(mobile: mobile, tablet: tablet, desktop: desktop);
}
