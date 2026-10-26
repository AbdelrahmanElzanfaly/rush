import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush/rush.dart';

import '../support/pump.dart';

const mobileKey = Key('mobile');
const tabletKey = Key('tablet');
const desktopKey = Key('desktop');
const fallbackKey = Key('fallback');

const allThree = RushWidget(
  mobile: SizedBox(key: mobileKey),
  tablet: SizedBox(key: tabletKey),
  desktop: SizedBox(key: desktopKey),
);

/// Asserts that [key] is the only one of the four slots on screen.
void expectOnly(Key key) {
  for (final candidate in [mobileKey, tabletKey, desktopKey, fallbackKey]) {
    expect(
      find.byKey(candidate),
      candidate == key ? findsOneWidget : findsNothing,
      reason: 'expected $key and nothing else',
    );
  }
}

void main() {
  tearDown(RushSetup.reset);

  group('slot selection', () {
    testWidgets('renders the mobile layout on a narrow window', (tester) async {
      await pumpAtWidth(tester, 400, allThree);
      expectOnly(mobileKey);
    });

    testWidgets('renders the tablet layout between the bounds', (tester) async {
      await pumpAtWidth(tester, 1000, allThree);
      expectOnly(tabletKey);
    });

    testWidgets('renders the desktop layout on a wide window', (tester) async {
      await pumpAtWidth(tester, 1600, allThree);
      expectOnly(desktopKey);
    });

    testWidgets('the tablet bound is inclusive', (tester) async {
      // Pre-0.1.0 this rendered the mobile layout: the comparison was `<=`.
      await pumpAtWidth(tester, 768, allThree);
      expectOnly(tabletKey);
    });

    testWidgets('the desktop bound is inclusive', (tester) async {
      await pumpAtWidth(tester, 1200, allThree);
      expectOnly(desktopKey);
    });

    testWidgets('one pixel below the desktop bound is still tablet',
        (tester) async {
      await pumpAtWidth(tester, 1199, allThree);
      expectOnly(tabletKey);
    });

    testWidgets('swaps layouts when the window is resized', (tester) async {
      await pumpAtWidth(tester, 400, allThree);
      expectOnly(mobileKey);
      await pumpAtWidth(tester, 1600, allThree);
      expectOnly(desktopKey);
    });
  });

  group('fallback chain', () {
    testWidgets('a lone mobile layout is used at every width', (tester) async {
      const widget = RushWidget(mobile: SizedBox(key: mobileKey));
      for (final width in [320.0, 768.0, 1000.0, 1200.0, 1920.0]) {
        await pumpAtWidth(tester, width, widget);
        expectOnly(mobileKey);
      }
    });

    testWidgets('tablet degrades to mobile before desktop', (tester) async {
      await pumpAtWidth(
        tester,
        1000,
        const RushWidget(
          mobile: SizedBox(key: mobileKey),
          desktop: SizedBox(key: desktopKey),
        ),
      );
      expectOnly(mobileKey);
    });

    testWidgets('desktop degrades to tablet before mobile', (tester) async {
      await pumpAtWidth(
        tester,
        1600,
        const RushWidget(
          mobile: SizedBox(key: mobileKey),
          tablet: SizedBox(key: tabletKey),
        ),
      );
      expectOnly(tabletKey);
    });

    testWidgets('mobile climbs to tablet when there is nothing narrower',
        (tester) async {
      await pumpAtWidth(
        tester,
        400,
        const RushWidget(
          tablet: SizedBox(key: tabletKey),
          desktop: SizedBox(key: desktopKey),
        ),
      );
      expectOnly(tabletKey);
    });

    testWidgets('mobile climbs to desktop when that is all there is',
        (tester) async {
      await pumpAtWidth(
        tester,
        400,
        const RushWidget(desktop: SizedBox(key: desktopKey)),
      );
      expectOnly(desktopKey);
    });

    testWidgets('renders fallback only when every slot is empty',
        (tester) async {
      await pumpAtWidth(
        tester,
        400,
        const RushWidget(fallback: SizedBox(key: fallbackKey)),
      );
      expectOnly(fallbackKey);
    });

    testWidgets('fallback is ignored when any slot exists', (tester) async {
      await pumpAtWidth(
        tester,
        1600,
        const RushWidget(
          mobile: SizedBox(key: mobileKey),
          fallback: SizedBox(key: fallbackKey),
        ),
      );
      expectOnly(mobileKey);
    });

    test('supplying nothing at all is an assertion error', () {
      // Pre-0.1.0 an unfilled slot shipped a hardcoded English Text widget to
      // production users; now it fails at development time instead.
      // Declared, not const-initialised, so the analyzer cannot fold this
      // into a `const RushWidget()` — which would fail to compile rather than
      // throw, since the assertion is const-evaluable.
      Widget? nothing;
      expect(() => RushWidget(mobile: nothing), throwsAssertionError);
    });

    test('resolveFor is pure and testable without pumping', () {
      const widget = RushWidget(
        mobile: SizedBox(key: mobileKey),
        desktop: SizedBox(key: desktopKey),
      );
      expect(widget.resolveFor(RushDeviceType.mobile).key, mobileKey);
      expect(widget.resolveFor(RushDeviceType.tablet).key, mobileKey);
      expect(widget.resolveFor(RushDeviceType.desktop).key, desktopKey);
      expect(widget.slotFor(RushDeviceType.tablet), isNull);
    });
  });

  group('breakpoint sources', () {
    testWidgets('honours globally configured bounds', (tester) async {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 500, desktop: 900),
        ),
      );
      await pumpAtWidth(tester, 600, allThree);
      expectOnly(tabletKey);
    });

    testWidgets('a later init changes what subsequent builds render',
        (tester) async {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 500, desktop: 900),
        ),
      );
      await pumpAtWidth(tester, 600, allThree);
      expectOnly(tabletKey);

      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 1000, desktop: 1400),
        ),
      );
      await pumpAtWidth(tester, 600, allThree);
      expectOnly(mobileKey);
    });

    testWidgets('measures its own box, not the window, by default',
        (tester) async {
      await pumpAtWidth(tester, 1600, boxed(300, allThree));
      expectOnly(mobileKey);
    });

    testWidgets('useWindowWidth ignores the enclosing box', (tester) async {
      await pumpAtWidth(
        tester,
        1600,
        boxed(
          300,
          const RushWidget(
            mobile: SizedBox(key: mobileKey),
            tablet: SizedBox(key: tabletKey),
            desktop: SizedBox(key: desktopKey),
            useWindowWidth: true,
          ),
        ),
      );
      expectOnly(desktopKey);
    });

    testWidgets('falls back to the window width when horizontally unbounded',
        (tester) async {
      // A Row hands its non-flexible children maxWidth: infinity. Classifying
      // that literally would pin every such widget to desktop forever.
      await pumpAtWidth(tester, 400, const Row(children: [allThree]));
      expectOnly(mobileKey);

      await pumpAtWidth(tester, 1600, const Row(children: [allThree]));
      expectOnly(desktopKey);
    });
  });

  group('screen remapping', () {
    testWidgets('a globally remapped size renders the other slot',
        (tester) async {
      // "No tablet design yet — show the desktop one there."
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await pumpAtWidth(tester, 1000, allThree);
      expectOnly(desktopKey);
    });

    testWidgets('leaves the sizes it does not name alone', (tester) async {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await pumpAtWidth(tester, 400, allThree);
      expectOnly(mobileKey);
      await pumpAtWidth(tester, 1600, allThree);
      expectOnly(desktopKey);
    });

    testWidgets('can point a size downward', (tester) async {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(desktop: RushDeviceType.tablet),
        ),
      );
      await pumpAtWidth(tester, 1600, allThree);
      expectOnly(tabletKey);
    });

    testWidgets('can collapse every size onto one layout', (tester) async {
      RushSetup.init(
        RushSetup.config.copyWith(screens: RushScreenMap.alwaysMobile),
      );
      for (final width in [320.0, 900.0, 1600.0]) {
        await pumpAtWidth(tester, width, allThree);
        expectOnly(mobileKey);
      }
    });

    testWidgets('a map can be replaced by a later init', (tester) async {
      RushSetup.init(
        RushSetup.config.copyWith(screens: RushScreenMap.alwaysMobile),
      );
      await pumpAtWidth(tester, 1600, allThree);
      expectOnly(mobileKey);

      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(desktop: RushDeviceType.tablet),
        ),
      );
      await pumpAtWidth(tester, 1600, allThree);
      expectOnly(tabletKey);
    });

    testWidgets('the map wins over the fallback chain', (tester) async {
      // Without the map, a tablet screen would fall back to mobile. The map
      // says otherwise, and the map is the deliberate choice.
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await pumpAtWidth(
        tester,
        1000,
        const RushWidget(
          mobile: SizedBox(key: mobileKey),
          desktop: SizedBox(key: desktopKey),
        ),
      );
      expectOnly(desktopKey);
    });

    testWidgets('the chain still catches a remap onto an empty slot',
        (tester) async {
      // Mapped to desktop, but there is no desktop layout — rather than render
      // nothing, the chain degrades from desktop.
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await pumpAtWidth(
        tester,
        1000,
        const RushWidget(mobile: SizedBox(key: mobileKey)),
      );
      expectOnly(mobileKey);
    });

    testWidgets('remapping composes with custom breakpoints', (tester) async {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 500, desktop: 900),
          screens: RushScreenMap(tablet: RushDeviceType.mobile),
        ),
      );
      await pumpAtWidth(tester, 600, allThree);
      expectOnly(mobileKey);
      await pumpAtWidth(tester, 950, allThree);
      expectOnly(desktopKey);
    });
  });

  group('diagnostics', () {
    test('reports which slots are populated', () {
      const widget = RushWidget(mobile: SizedBox(key: mobileKey));
      expect(widget.toStringDeep(), contains('has mobile'));
    });
  });
}
