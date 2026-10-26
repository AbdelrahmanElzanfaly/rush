import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush/rush.dart';

void main() {
  group('defaults', () {
    test('an empty config is the standard one', () {
      expect(const RushConfig(), RushConfig.standard);
      expect(const RushConfig().isStandard, isTrue);
      expect(RushConfig.standard.breakpoints, RushBreakpoints.standard);
      expect(RushConfig.standard.screens, RushScreenMap.identity);
    });

    test('naming one knob leaves the other at its default', () {
      const config = RushConfig(screens: RushScreenMap.alwaysMobile);
      expect(config.breakpoints, RushBreakpoints.standard);
      expect(config.screens, RushScreenMap.alwaysMobile);
      expect(config.isStandard, isFalse);
    });

    test('the material3 preset uses those breakpoints and no remapping', () {
      expect(RushConfig.material3.breakpoints, RushBreakpoints.material3);
      expect(RushConfig.material3.screens, RushScreenMap.identity);
    });
  });

  group('classification', () {
    test('detectedForWidth ignores the screen map', () {
      const config = RushConfig(screens: RushScreenMap.alwaysMobile);
      expect(config.detectedForWidth(1600), RushDeviceType.desktop);
      expect(config.detectedForWidth(900), RushDeviceType.tablet);
    });

    test('slotForWidth applies the screen map', () {
      const config = RushConfig(screens: RushScreenMap.alwaysMobile);
      expect(config.slotForWidth(1600), RushDeviceType.mobile);
      expect(config.slotForWidth(900), RushDeviceType.mobile);
    });

    test('the two agree when no mapping is configured', () {
      for (final width in [320.0, 768.0, 1000.0, 1200.0, 1920.0]) {
        expect(
          RushConfig.standard.slotForWidth(width),
          RushConfig.standard.detectedForWidth(width),
        );
      }
    });

    test('breakpoints and screens compose', () {
      const config = RushConfig(
        breakpoints: RushBreakpoints(tablet: 500, desktop: 900),
        screens: RushScreenMap(tablet: RushDeviceType.desktop),
      );
      expect(config.slotForWidth(400), RushDeviceType.mobile);
      expect(config.slotForWidth(600), RushDeviceType.desktop);
      expect(config.slotForWidth(1000), RushDeviceType.desktop);
      expect(config.detectedForWidth(600), RushDeviceType.tablet);
    });
  });

  group('resolve', () {
    test('picks the value for the width', () {
      const config = RushConfig();
      expect(
        config.resolve(width: 400, mobile: 'S', tablet: 'M', desktop: 'L'),
        'S',
      );
      expect(
        config.resolve(width: 900, mobile: 'S', tablet: 'M', desktop: 'L'),
        'M',
      );
      expect(
        config.resolve(width: 1600, mobile: 'S', tablet: 'M', desktop: 'L'),
        'L',
      );
    });

    test('honours the screen map', () {
      const config = RushConfig(
        screens: RushScreenMap(desktop: RushDeviceType.mobile),
      );
      expect(
        config.resolve(width: 1600, mobile: 'S', tablet: 'M', desktop: 'L'),
        'S',
      );
    });

    test('is generic over the value type', () {
      const config = RushConfig();
      expect(
        config.resolve<Size>(
          width: 1600,
          mobile: const Size(320, 480),
          tablet: const Size(768, 1024),
          desktop: const Size(1440, 900),
        ),
        const Size(1440, 900),
      );
    });
  });

  group('value semantics', () {
    test('equal configs compare equal and hash alike', () {
      const a = RushConfig(
        breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
        screens: RushScreenMap.alwaysMobile,
      );
      const b = RushConfig(
        breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
        screens: RushScreenMap.alwaysMobile,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(RushConfig.standard));
    });

    test('copyWith replaces only the named field', () {
      const a = RushConfig(
        breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
      );
      final b = a.copyWith(screens: RushScreenMap.alwaysMobile);
      expect(b.breakpoints, a.breakpoints);
      expect(b.screens, RushScreenMap.alwaysMobile);
      expect(a.copyWith(), a);
    });

    test('toString mentions both knobs', () {
      final text = RushConfig.standard.toString();
      expect(text, contains('RushBreakpoints'));
      expect(text, contains('RushScreenMap'));
    });
  });

  group('validate', () {
    test('accepts a sane config', () {
      expect(RushConfig.standard.validate, returnsNormally);
      expect(RushConfig.material3.validate, returnsNormally);
    });

    test('rejects unusable breakpoints', () {
      // Built through a function so the arguments are not compile-time
      // constants; a const version would not compile at all.
      RushConfig make(double tablet, double desktop) => RushConfig(
            breakpoints: RushBreakpoints(tablet: tablet, desktop: desktop),
          );
      expect(
        () => make(1400, 1200),
        throwsA(anyOf(isA<AssertionError>(), isA<ArgumentError>())),
      );
    });
  });
}
