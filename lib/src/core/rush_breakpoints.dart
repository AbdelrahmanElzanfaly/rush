import 'package:flutter/foundation.dart';

import 'rush_device_type.dart';

/// An immutable pair of width thresholds that splits the width axis into the
/// three [RushDeviceType] classes.
///
/// [tablet] is the width at which a screen stops being
/// [RushDeviceType.mobile]; [desktop] is the width at which it stops being
/// [RushDeviceType.tablet]. Both bounds are inclusive lower bounds, so a
/// width of exactly [tablet] is already [RushDeviceType.tablet].
///
/// ```dart
/// const breakpoints = RushBreakpoints(tablet: 600, desktop: 1024);
/// breakpoints.typeOf(599); // RushDeviceType.mobile
/// breakpoints.typeOf(600); // RushDeviceType.tablet
/// ```
@immutable
class RushBreakpoints {
  /// Creates a set of breakpoints.
  ///
  /// [tablet] must be greater than zero and strictly less than [desktop], and
  /// both must be finite. Violating this is a programming error: it is caught
  /// at compile time for `const` instances and by an assertion in debug mode.
  /// `RushSetup.init` additionally calls [validate] at runtime so release
  /// builds fail loudly rather than silently rendering a dead branch.
  const RushBreakpoints({
    this.tablet = defaultTablet,
    this.desktop = defaultDesktop,
  })  : assert(tablet > 0, 'tablet breakpoint must be greater than zero'),
        assert(
          tablet < desktop,
          'tablet breakpoint must be strictly less than the desktop '
          'breakpoint, otherwise the tablet range is empty and can never be '
          'selected',
        );

  /// The default width at which [RushDeviceType.tablet] begins.
  static const double defaultTablet = 768;

  /// The default width at which [RushDeviceType.desktop] begins.
  static const double defaultDesktop = 1200;

  /// Rush's default breakpoints: 768 and 1200 logical pixels.
  static const RushBreakpoints standard = RushBreakpoints();

  /// Material 3 window size classes, collapsed to Rush's three tiers.
  ///
  /// Compact (`< 600`) maps to [RushDeviceType.mobile], tablet (`600–839`) to
  /// [RushDeviceType.tablet], and expanded (`>= 840`) to
  /// [RushDeviceType.desktop].
  static const RushBreakpoints material3 =
      RushBreakpoints(tablet: 600, desktop: 840);

  /// The inclusive lower bound of [RushDeviceType.tablet], in logical pixels.
  final double tablet;

  /// The inclusive lower bound of [RushDeviceType.desktop], in logical pixels.
  final double desktop;

  /// Classifies [width] into a [RushDeviceType].
  ///
  /// `double.nan` and any negative width resolve to [RushDeviceType.mobile],
  /// and `double.infinity` resolves to [RushDeviceType.desktop], so an
  /// unbounded layout degrades instead of throwing.
  RushDeviceType typeOf(double width) {
    if (width.isNaN || width < tablet) return RushDeviceType.mobile;
    if (width < desktop) return RushDeviceType.tablet;
    return RushDeviceType.desktop;
  }

  /// Returns a copy with the given fields replaced.
  RushBreakpoints copyWith({double? tablet, double? desktop}) =>
      RushBreakpoints(
        tablet: tablet ?? this.tablet,
        desktop: desktop ?? this.desktop,
      );

  /// Throws an [ArgumentError] if these breakpoints are not usable.
  ///
  /// Unlike the constructor's assertions this runs in release builds too.
  void validate() {
    if (!tablet.isFinite || tablet <= 0) {
      throw ArgumentError.value(
        tablet,
        'tablet',
        'must be a finite number greater than zero',
      );
    }
    if (!desktop.isFinite) {
      throw ArgumentError.value(desktop, 'desktop', 'must be a finite number');
    }
    if (tablet >= desktop) {
      throw ArgumentError(
        'tablet ($tablet) must be strictly less than desktop ($desktop); '
        'otherwise no width can ever resolve to RushDeviceType.tablet.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RushBreakpoints &&
          other.tablet == tablet &&
          other.desktop == desktop;

  @override
  int get hashCode => Object.hash(tablet, desktop);

  @override
  String toString() => 'RushBreakpoints(tablet: $tablet, desktop: $desktop)';
}
