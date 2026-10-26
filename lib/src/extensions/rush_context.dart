import 'package:flutter/widgets.dart';

import '../core/rush_device_type.dart';
import '../rush_setup.dart';

/// Breakpoint helpers on [BuildContext].
///
/// Everything here is keyed off the **window** width via `MediaQuery`, which
/// makes it convenient for one-off decisions inside a build method:
///
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(context.isMobile ? 12 : 24),
///   child: Text('hi', style: context.rushValue(
///     mobile: theme.textTheme.titleMedium,
///     desktop: theme.textTheme.headlineSmall,
///   )),
/// )
/// ```
///
/// Reading any of these establishes a dependency on the ambient [MediaQuery],
/// so the widget rebuilds when the window is resized.
///
/// These accessors deliberately ignore the enclosing box. For a widget that
/// should adapt to the space *it* was given — a panel, a sidebar, a dialog —
/// use `RushBuilder` or `RushWidget`, which measure real constraints.
extension RushBuildContext on BuildContext {
  /// The layout slot the current window should render.
  ///
  /// This is the detected screen class with `RushSetup.screens` applied, so
  /// it agrees with what `RushWidget` and `RushBuilder` decide. Use
  /// [rushDetectedDevice] when you need the raw classification.
  ///
  /// Throws if there is no [MediaQuery] ancestor; use [maybeRushDevice] if the
  /// widget can legitimately build outside one.
  RushDeviceType get rushDevice => RushSetup.of(this);

  /// The raw screen class of the current window, ignoring any screen mapping.
  ///
  /// Answers *how wide is this window*, where [rushDevice] answers *what should
  /// it render*. The two differ only when a mapping is configured.
  RushDeviceType get rushDetectedDevice => RushSetup.detectedOf(this);

  /// The layout slot for the current window, or null with no [MediaQuery].
  RushDeviceType? get maybeRushDevice {
    final size = MediaQuery.maybeSizeOf(this);
    return size == null ? null : RushSetup.typeOf(size.width);
  }

  /// Whether the window is [RushDeviceType.mobile].
  bool get isMobile => rushDevice.isMobile;

  /// Whether the window is [RushDeviceType.tablet].
  bool get isTablet => rushDevice.isTablet;

  /// Whether the window is [RushDeviceType.desktop].
  bool get isDesktop => rushDevice.isDesktop;

  /// The window width in logical pixels.
  double get rushWidth => MediaQuery.sizeOf(this).width;

  /// Picks a value for the current window size.
  ///
  /// [mobile] is required; [tablet] and [desktop] fall back to the next
  /// narrower value when omitted, so `context.rushValue(mobile: 8)` returns `8`
  /// everywhere and `context.rushValue(mobile: 8, desktop: 24)` returns `8` on
  /// tablet screens.
  ///
  /// ```dart
  /// final columns = context.rushValue(mobile: 1, tablet: 2, desktop: 4);
  /// ```
  T rushValue<T>({required T mobile, T? tablet, T? desktop}) =>
      switch (rushDevice) {
        RushDeviceType.mobile => mobile,
        RushDeviceType.tablet => tablet ?? mobile,
        RushDeviceType.desktop => desktop ?? tablet ?? mobile,
      };
}
