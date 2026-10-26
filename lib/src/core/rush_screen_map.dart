import 'package:flutter/foundation.dart';

import 'rush_device_type.dart';

/// Redirects a detected screen class onto a different layout slot.
///
/// Breakpoints answer *what size is this screen*. A `RushScreenMap` answers
/// the separate question *which layout should that size render*. By default
/// they are the same — a tablet screen renders the tablet layout — but they
/// do not have to be.
///
/// The motivating case is a layout you have not written yet. If there is no
/// tablet design, say so explicitly and pick the one to borrow:
///
/// ```dart
/// RushSetup.init(const RushConfig(
///   screens: RushScreenMap(tablet: RushDeviceType.desktop),
/// ));
/// ```
///
/// Now a tablet-width window renders the `desktop` layout, and it keeps doing
/// so until you write a real tablet design and delete the line. The intent is
/// recorded in one place rather than implied by an absent argument at every
/// call site.
///
/// Read a field as *"screens of this size render that slot"*:
///
/// ```dart
/// const RushScreenMap(tablet: RushDeviceType.desktop)
/// //                 ^ a tablet screen  ^ renders the desktop layout
/// ```
///
/// ### Relationship to the fallback chain
///
/// The map runs first and decides which slot to *ask* for. The fallback chain
/// in `RushWidget` only runs afterwards, if the slot it landed on turns out
/// to be null. So the map is the deliberate choice and the chain is the
/// safety net:
///
/// ```dart
/// RushSetup.init(const RushConfig(
///   screens: RushScreenMap(tablet: RushDeviceType.desktop),
/// ));
///
/// RushWidget(mobile: Phone(), desktop: Desktop())  // tablet -> Desktop
/// RushWidget(mobile: Phone())                    // tablet -> desktop is null,
///                                               // chain falls back to Phone
/// ```
@immutable
class RushScreenMap {
  /// Creates a mapping from detected screen class to layout slot.
  ///
  /// Every field defaults to itself, so
  /// `const RushScreenMap(tablet: RushDeviceType.desktop)` changes tablet
  /// screens and leaves mobile and desktop alone.
  const RushScreenMap({
    this.mobile = RushDeviceType.mobile,
    this.tablet = RushDeviceType.tablet,
    this.desktop = RushDeviceType.desktop,
  });

  /// Every screen class renders its own layout. The default.
  static const RushScreenMap identity = RushScreenMap();

  /// Renders the mobile layout everywhere.
  ///
  /// Useful early on, when only the phone design exists and you want the
  /// desktop to show it rather than an empty box.
  static const RushScreenMap alwaysMobile = RushScreenMap(
    tablet: RushDeviceType.mobile,
    desktop: RushDeviceType.mobile,
  );

  /// The slot a [RushDeviceType.mobile] screen renders.
  final RushDeviceType mobile;

  /// The slot a [RushDeviceType.tablet] screen renders.
  final RushDeviceType tablet;

  /// The slot a [RushDeviceType.desktop] screen renders.
  final RushDeviceType desktop;

  /// The slot that [detected] should render.
  RushDeviceType slotFor(RushDeviceType detected) => switch (detected) {
        RushDeviceType.mobile => mobile,
        RushDeviceType.tablet => tablet,
        RushDeviceType.desktop => desktop,
      };

  /// Whether every screen class renders its own layout.
  bool get isIdentity =>
      mobile == RushDeviceType.mobile &&
      tablet == RushDeviceType.tablet &&
      desktop == RushDeviceType.desktop;

  /// Returns a copy with the given fields replaced.
  RushScreenMap copyWith({
    RushDeviceType? mobile,
    RushDeviceType? tablet,
    RushDeviceType? desktop,
  }) =>
      RushScreenMap(
        mobile: mobile ?? this.mobile,
        tablet: tablet ?? this.tablet,
        desktop: desktop ?? this.desktop,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RushScreenMap &&
          other.mobile == mobile &&
          other.tablet == tablet &&
          other.desktop == desktop;

  @override
  int get hashCode => Object.hash(mobile, tablet, desktop);

  @override
  String toString() => isIdentity
      ? 'RushScreenMap.identity'
      : 'RushScreenMap(mobile -> ${mobile.name}, tablet -> ${tablet.name}, '
          'desktop -> ${desktop.name})';
}
