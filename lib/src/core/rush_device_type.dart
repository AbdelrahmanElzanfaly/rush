import 'package:flutter/widgets.dart';

import '../rush_setup.dart';

/// The three device classes Rush recognises.
///
/// These are names for width bands, not detected hardware. Rush never asks
/// the platform what it is running on — a desktop window dragged narrow is
/// [mobile], and a `RushWidget` inside a 300px panel is [mobile] even on a
/// 4K monitor. The names describe the layout you would design for that much
/// room.
///
/// A width is classified by `RushBreakpoints.typeOf` using half-open ranges:
///
/// ```text
/// [0, tablet)         -> RushDeviceType.mobile
/// [tablet, desktop)   -> RushDeviceType.tablet
/// [desktop, ...)      -> RushDeviceType.desktop
/// ```
///
/// With the default breakpoints (768 / 1200) that means a width of exactly
/// `768` is [tablet] and a width of exactly `1200` is [desktop].
enum RushDeviceType {
  /// Phones and narrow windows. Anything below [RushBreakpoints.tablet].
  mobile,

  /// Tablets and split-screen windows.
  tablet,

  /// Desktops and wide windows. Anything at or above [RushBreakpoints.desktop].
  desktop;

  /// The layout slot the current window should render.
  ///
  /// Shorthand for [RushSetup.of], so any configured screen mapping is
  /// already applied. Establishes a dependency on the ambient `MediaQuery`,
  /// so the caller rebuilds when the window is resized.
  static RushDeviceType of(BuildContext context) => RushSetup.of(context);

  /// Whether this is [RushDeviceType.mobile].
  bool get isMobile => this == RushDeviceType.mobile;

  /// Whether this is [RushDeviceType.tablet].
  bool get isTablet => this == RushDeviceType.tablet;

  /// Whether this is [RushDeviceType.desktop].
  bool get isDesktop => this == RushDeviceType.desktop;

  /// Picks one of three values for this device class.
  ///
  /// A pure switch, so it works anywhere you already hold a type — most often
  /// one handed to you by `RushBuilder`:
  ///
  /// ```dart
  /// RushBuilder(
  ///   builder: (context, type, _) => GridView.count(
  ///     crossAxisCount: type.pick(mobile: 1, tablet: 2, desktop: 4),
  ///     children: tiles,
  ///   ),
  /// )
  /// ```
  ///
  /// Works for any value type. When you have a width rather than a device
  /// class, use `RushConfig.resolve`, which classifies first and then picks.
  T pick<T>({required T mobile, required T tablet, required T desktop}) =>
      switch (this) {
        RushDeviceType.mobile => mobile,
        RushDeviceType.tablet => tablet,
        RushDeviceType.desktop => desktop,
      };

  /// Whether this class is at least as wide as [other].
  ///
  /// They are ordered `mobile < tablet < desktop`, so
  /// `RushDeviceType.desktop.isAtLeast(RushDeviceType.tablet)` is `true`.
  bool isAtLeast(RushDeviceType other) => index >= other.index;

  /// Whether this class is at most as wide as [other].
  bool isAtMost(RushDeviceType other) => index <= other.index;

  /// The order Rush walks when the slot for this class was not supplied.
  ///
  /// Rush degrades *downward* first — a layout designed for a narrower screen
  /// still renders correctly on a wider one, while the reverse tends to
  /// overflow. [mobile] has nothing below it, so it degrades upward.
  ///
  /// The first entry is always the class itself.
  List<RushDeviceType> get fallbackOrder => switch (this) {
        RushDeviceType.mobile => const [
            RushDeviceType.mobile,
            RushDeviceType.tablet,
            RushDeviceType.desktop,
          ],
        RushDeviceType.tablet => const [
            RushDeviceType.tablet,
            RushDeviceType.mobile,
            RushDeviceType.desktop,
          ],
        RushDeviceType.desktop => const [
            RushDeviceType.desktop,
            RushDeviceType.tablet,
            RushDeviceType.mobile,
          ],
      };
}
