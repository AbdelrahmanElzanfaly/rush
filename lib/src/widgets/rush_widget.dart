import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/rush_device_type.dart';
import '../core/rush_screen_map.dart';
import 'rush_builder.dart';

/// Renders one of three layouts depending on how much width is available.
///
/// ```dart
/// RushWidget(
///   mobile: MobileHome(),
///   tablet: TabletHome(),
///   desktop: DesktopHome(),
/// )
/// ```
///
/// ### Borrowing another size's layout
///
/// If a design does not exist yet, say which one to use in its place instead
/// of leaving it to chance:
///
/// ```dart
/// // Tablets render the desktop layout, everywhere in the app.
/// RushSetup.init(const RushConfig(
///   screens: RushScreenMap(tablet: RushDeviceType.desktop),
/// ));
/// ```
///
/// The mapping decides which slot Rush asks for; the fallback chain below
/// only runs if that slot turns out to be null.
///
/// ### Missing slots
///
/// Every slot is optional and you never have to supply all three. When the
/// slot Rush asked for is null, it walks
/// [RushDeviceType.fallbackOrder] and renders the closest one you did
/// provide, preferring a *narrower* layout because a narrow layout survives a
/// wide screen while a wide layout overflows a narrow one:
///
/// | resolved size | tries, in order        |
/// |---------------|------------------------|
/// | mobile         | mobile → tablet → desktop |
/// | tablet        | tablet → mobile → desktop |
/// | desktop         | desktop → tablet → mobile |
///
/// So `RushWidget(mobile: Foo())` renders `Foo` at every width, and
/// `RushWidget(mobile: Phone(), desktop: Desktop())` renders `Phone` on tablet
/// screens.
///
/// Supplying nothing at all is a programming error and trips an assertion in
/// debug builds; release builds render [fallback], or an empty box if there
/// is no [fallback].
///
/// ### Which width?
///
/// Width comes from the incoming [BoxConstraints], so a `RushWidget` placed
/// in a narrow sidebar behaves as mobile even on a desktop. Pass
/// `useWindowWidth: true` to switch to the window width instead.
///
/// See also:
///
///  * [RushBuilder], for when the branches share code and you want a callback
///    with the resolved [RushDeviceType] rather than three whole widgets.
class RushWidget extends StatelessWidget {
  /// Creates a responsive switch between up to three layouts.
  ///
  /// At least one of [mobile], [tablet], [desktop] or [fallback] must be
  /// non-null.
  const RushWidget({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
    this.useWindowWidth = false,
  }) : assert(
          mobile != null ||
              tablet != null ||
              desktop != null ||
              fallback != null,
          'RushWidget needs at least one of mobile, tablet, desktop or '
          'fallback; with all four null it can only ever render an empty box.',
        );

  /// Layout for [RushDeviceType.mobile].
  final Widget? mobile;

  /// Layout for [RushDeviceType.tablet].
  final Widget? tablet;

  /// Layout for [RushDeviceType.desktop].
  final Widget? desktop;

  /// Rendered only when [mobile], [tablet] and [desktop] are all null.
  ///
  /// This is a guard for the degenerate case, not a default branch: if any
  /// slot is set, the fallback chain reaches it first and [fallback] is never
  /// used.
  final Widget? fallback;

  /// Measure the whole window instead of the incoming constraints.
  ///
  /// Defaults to `false`.
  final bool useWindowWidth;

  /// The slot registered for [type], or null if it was not supplied.
  Widget? slotFor(RushDeviceType type) => switch (type) {
        RushDeviceType.mobile => mobile,
        RushDeviceType.tablet => tablet,
        RushDeviceType.desktop => desktop,
      };

  /// The widget that [type] resolves to after applying the fallback chain.
  ///
  /// [type] is expected to be a layout slot — that is, already through any
  /// [RushScreenMap]. Returns [fallback], or an empty box, when no slot is
  /// available.
  Widget resolveFor(RushDeviceType type) {
    for (final candidate in type.fallbackOrder) {
      final widget = slotFor(candidate);
      if (widget != null) return widget;
    }
    return fallback ?? const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return RushBuilder(
      useWindowWidth: useWindowWidth,
      builder: (context, type, constraints) => resolveFor(type),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('mobile', value: mobile != null, ifTrue: 'has mobile'))
      ..add(FlagProperty('tablet', value: tablet != null, ifTrue: 'has tablet'))
      ..add(
        FlagProperty(
          'desktop',
          value: desktop != null,
          ifTrue: 'has desktop',
        ),
      )
      ..add(
        FlagProperty(
          'useWindowWidth',
          value: useWindowWidth,
          ifTrue: 'measures window',
        ),
      );
  }
}
