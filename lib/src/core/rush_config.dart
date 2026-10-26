import 'package:flutter/foundation.dart';

import 'rush_breakpoints.dart';
import 'rush_device_type.dart';
import 'rush_screen_map.dart';

/// A complete responsive configuration.
///
/// Rush has exactly two knobs, and this groups them:
///
///  * [breakpoints] — the widths at which the screen class changes.
///  * [screens] — which layout slot each screen class renders.
///
/// Passing them as one object keeps related settings together, makes the
/// whole configuration `const`, comparable and loggable, and means
/// `RushSetup.init` takes one argument instead of five loose ones:
///
/// ```dart
/// RushSetup.init(const RushConfig(
///   breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
///   screens: RushScreenMap(tablet: RushDeviceType.desktop),
/// ));
/// ```
///
/// Both fields have defaults, so `const RushConfig()` is Rush's out-of-the-box
/// behaviour and you only name what you are changing.
///
/// This class also owns the classification logic — [slotForWidth] and
/// [detectedForWidth] — because it is the object that holds everything the
/// decision needs.
@immutable
class RushConfig {
  /// Creates a configuration.
  const RushConfig({
    this.breakpoints = RushBreakpoints.standard,
    this.screens = RushScreenMap.identity,
  });

  /// Rush's defaults: [RushBreakpoints.standard] (768 / 1200) and
  /// [RushScreenMap.identity] (every size renders its own layout).
  static const RushConfig standard = RushConfig();

  /// Material 3 window size classes, with no screen remapping.
  static const RushConfig material3 =
      RushConfig(breakpoints: RushBreakpoints.material3);

  /// Where the screen class changes.
  final RushBreakpoints breakpoints;

  /// Which layout slot each screen class renders.
  final RushScreenMap screens;

  /// Whether this is the untouched default configuration.
  bool get isStandard => this == standard;

  /// The raw screen class of [width], ignoring [screens].
  ///
  /// Answers *how wide is this*, where [slotForWidth] answers *what should it
  /// render*. The two differ only when a screen mapping is configured.
  RushDeviceType detectedForWidth(double width) => breakpoints.typeOf(width);

  /// The layout slot [width] should render.
  ///
  /// The detected screen class with [screens] applied. This is what
  /// `RushWidget` and `RushBuilder` branch on.
  RushDeviceType slotForWidth(double width) =>
      screens.slotFor(detectedForWidth(width));

  /// Picks one of three values for the given [width].
  ///
  /// Honours [screens], so a remapped size picks the value it renders as.
  /// Works for any type — `Size`, `double`, `EdgeInsets`, `TextStyle`, an int
  /// column count, and so on.
  ///
  /// ```dart
  /// final columns =
  ///     config.resolve(width: 900, mobile: 1, tablet: 2, desktop: 4);
  /// ```
  T resolve<T>({
    required double width,
    required T mobile,
    required T tablet,
    required T desktop,
  }) =>
      slotForWidth(width)
          .pick(mobile: mobile, tablet: tablet, desktop: desktop);

  /// Returns a copy with the given fields replaced.
  ///
  /// The idiomatic way to change one knob:
  ///
  /// ```dart
  /// RushSetup.init(RushSetup.config.copyWith(
  ///   screens: RushScreenMap.alwaysMobile,
  /// ));
  /// ```
  RushConfig copyWith({
    RushBreakpoints? breakpoints,
    RushScreenMap? screens,
  }) =>
      RushConfig(
        breakpoints: breakpoints ?? this.breakpoints,
        screens: screens ?? this.screens,
      );

  /// Throws an [ArgumentError] if this configuration is not usable.
  ///
  /// Delegates to [RushBreakpoints.validate]; a [RushScreenMap] cannot be
  /// invalid.
  void validate() => breakpoints.validate();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RushConfig &&
          other.breakpoints == breakpoints &&
          other.screens == screens;

  @override
  int get hashCode => Object.hash(breakpoints, screens);

  @override
  String toString() => 'RushConfig($breakpoints, $screens)';
}
