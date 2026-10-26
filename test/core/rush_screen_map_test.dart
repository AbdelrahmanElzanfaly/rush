import 'package:flutter_test/flutter_test.dart';
import 'package:rush/rush.dart';

void main() {
  tearDown(RushSetup.reset);

  group('RushScreenMap.slotFor', () {
    test('identity maps every size to itself', () {
      for (final size in RushDeviceType.values) {
        expect(RushScreenMap.identity.slotFor(size), size);
      }
    });

    test('redirects only the size it names', () {
      const map = RushScreenMap(tablet: RushDeviceType.desktop);
      expect(map.slotFor(RushDeviceType.mobile), RushDeviceType.mobile);
      expect(map.slotFor(RushDeviceType.tablet), RushDeviceType.desktop);
      expect(map.slotFor(RushDeviceType.desktop), RushDeviceType.desktop);
    });

    test('can point a size downward', () {
      const map = RushScreenMap(desktop: RushDeviceType.tablet);
      expect(map.slotFor(RushDeviceType.desktop), RushDeviceType.tablet);
    });

    test('can collapse everything onto one slot', () {
      for (final size in RushDeviceType.values) {
        expect(RushScreenMap.alwaysMobile.slotFor(size), RushDeviceType.mobile);
      }
    });

    test('can swap two sizes', () {
      const map = RushScreenMap(
        mobile: RushDeviceType.desktop,
        desktop: RushDeviceType.mobile,
      );
      expect(map.slotFor(RushDeviceType.mobile), RushDeviceType.desktop);
      expect(map.slotFor(RushDeviceType.desktop), RushDeviceType.mobile);
      expect(map.slotFor(RushDeviceType.tablet), RushDeviceType.tablet);
    });
  });

  group('RushScreenMap value semantics', () {
    test('isIdentity is true only for the untouched map', () {
      expect(RushScreenMap.identity.isIdentity, isTrue);
      expect(const RushScreenMap().isIdentity, isTrue);
      expect(RushScreenMap.alwaysMobile.isIdentity, isFalse);
      expect(
        const RushScreenMap(tablet: RushDeviceType.desktop).isIdentity,
        isFalse,
      );
    });

    test('equal maps compare equal and hash alike', () {
      const a = RushScreenMap(tablet: RushDeviceType.desktop);
      const b = RushScreenMap(tablet: RushDeviceType.desktop);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(RushScreenMap.identity));
    });

    test('copyWith replaces only the named field', () {
      const a = RushScreenMap(tablet: RushDeviceType.desktop);
      expect(
        a.copyWith(mobile: RushDeviceType.tablet),
        const RushScreenMap(
          mobile: RushDeviceType.tablet,
          tablet: RushDeviceType.desktop,
        ),
      );
      expect(a.copyWith().tablet, RushDeviceType.desktop);
    });

    test('toString names the redirections', () {
      expect(RushScreenMap.identity.toString(), 'RushScreenMap.identity');
      expect(
        const RushScreenMap(tablet: RushDeviceType.desktop).toString(),
        contains('tablet -> desktop'),
      );
    });
  });

  group('RushSetup screen mapping', () {
    test('defaults to identity', () {
      expect(RushSetup.screens, RushScreenMap.identity);
      expect(RushSetup.typeOf(900), RushDeviceType.tablet);
    });

    test('init accepts the per-size redirections', () {
      // The shape this package shipped in 0.0.1, preserved.
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(desktop: RushDeviceType.tablet),
        ),
      );
      expect(RushSetup.typeOf(1600), RushDeviceType.tablet);
      expect(RushSetup.typeOf(900), RushDeviceType.tablet);
      expect(RushSetup.typeOf(400), RushDeviceType.mobile);
    });

    test('init combines redirections with custom breakpoints', () {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 600, desktop: 1000),
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      expect(RushSetup.typeOf(599), RushDeviceType.mobile);
      expect(RushSetup.typeOf(600), RushDeviceType.desktop);
      expect(RushSetup.typeOf(1000), RushDeviceType.desktop);
    });

    test('init resets omitted redirections to identity', () {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      RushSetup.init();
      expect(RushSetup.screens, RushScreenMap.identity);
    });

    test('detectedTypeOf ignores the mapping', () {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(desktop: RushDeviceType.mobile),
        ),
      );
      expect(RushSetup.typeOf(1600), RushDeviceType.mobile);
      expect(RushSetup.detectedTypeOf(1600), RushDeviceType.desktop);
    });

    test('copyWith changes one knob without restating the other', () {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 600, desktop: 1000),
        ),
      );
      RushSetup.init(
        RushSetup.config.copyWith(screens: RushScreenMap.alwaysMobile),
      );
      expect(RushSetup.startTabletSize, 600);
      expect(RushSetup.screens, RushScreenMap.alwaysMobile);

      RushSetup.init(
        RushSetup.config.copyWith(breakpoints: RushBreakpoints.material3),
      );
      expect(RushSetup.screens, RushScreenMap.alwaysMobile);
      expect(RushSetup.startTabletSize, 600);
    });

    test('a rejected config leaves everything intact', () {
      RushSetup.init(
        RushSetup.config.copyWith(screens: RushScreenMap.alwaysMobile),
      );
      expect(
        () => RushSetup.init(
          RushConfig(
            breakpoints: RushBreakpoints(tablet: 1400, desktop: 1200),
          ),
        ),
        throwsA(anyOf(isA<AssertionError>(), isA<ArgumentError>())),
      );
      expect(RushSetup.screens, RushScreenMap.alwaysMobile);
      expect(RushSetup.startTabletSize, 768);
    });

    test('reset restores identity', () {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(desktop: RushDeviceType.mobile),
        ),
      );
      RushSetup.reset();
      expect(RushSetup.screens, RushScreenMap.identity);
    });

    test('resolve honours the mapping', () {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(desktop: RushDeviceType.mobile),
        ),
      );
      expect(
        RushSetup.resolve(width: 1600, mobile: 'S', tablet: 'M', desktop: 'L'),
        'S',
      );
    });
  });
}
