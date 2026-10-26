import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush/rush.dart';

void main() {
  tearDown(RushSetup.reset);

  group('defaults', () {
    test('works before init is ever called', () {
      // Pre-0.1.0 these were `late` statics: reading them without calling
      // init() threw LateInitializationError.
      expect(RushSetup.breakpoints, RushBreakpoints.standard);
      expect(RushSetup.startTabletSize, 768);
      expect(RushSetup.startDesktopSize, 1200);
      expect(RushSetup.typeOf(400), RushDeviceType.mobile);
    });
  });

  group('init', () {
    test('applies the given bounds', () {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
        ),
      );
      expect(RushSetup.startTabletSize, 600);
      expect(RushSetup.startDesktopSize, 1024);
      expect(RushSetup.typeOf(700), RushDeviceType.tablet);
    });

    test('is idempotent and can be called repeatedly', () {
      // Pre-0.1.0 the bounds were `late final`, so a second call — a hot
      // restart, a second test — threw LateInitializationError.
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
        ),
      );
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 700, desktop: 1100),
        ),
      );
      RushSetup.init();
      expect(RushSetup.breakpoints, RushBreakpoints.standard);
    });

    test('leaves the previous configuration intact when it rejects input', () {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
        ),
      );
      expect(
        () => RushSetup.init(
          RushConfig(
            breakpoints: RushBreakpoints(tablet: 1400, desktop: 1200),
          ),
        ),
        throwsA(anyOf(isA<AssertionError>(), isA<ArgumentError>())),
      );
      expect(RushSetup.startTabletSize, 600);
      expect(RushSetup.startDesktopSize, 1024);
    });

    test('accepts a preset config', () {
      RushSetup.init(
        RushSetup.config.copyWith(breakpoints: RushBreakpoints.material3),
      );
      expect(RushSetup.typeOf(840), RushDeviceType.desktop);
    });

    test('reset restores the standard bounds', () {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 300, desktop: 400),
        ),
      );
      RushSetup.reset();
      expect(RushSetup.breakpoints, RushBreakpoints.standard);
    });
  });

  group('resolve', () {
    test('picks the value matching the width', () {
      expect(
        RushSetup.resolve(width: 400, mobile: 'S', tablet: 'M', desktop: 'L'),
        'S',
      );
      expect(
        RushSetup.resolve(width: 900, mobile: 'S', tablet: 'M', desktop: 'L'),
        'M',
      );
      expect(
        RushSetup.resolve(width: 1600, mobile: 'S', tablet: 'M', desktop: 'L'),
        'L',
      );
    });

    test('is generic over the value type', () {
      final size = RushSetup.resolve<Size>(
        width: 1600,
        mobile: const Size(320, 480),
        tablet: const Size(768, 1024),
        desktop: const Size(1440, 900),
      );
      expect(size, const Size(1440, 900));

      final columns =
          RushSetup.resolve<int>(width: 900, mobile: 1, tablet: 2, desktop: 4);
      expect(columns, 2);
    });

    test('follows the configured bounds, not the defaults', () {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
        ),
      );
      expect(
        RushSetup.resolve(width: 700, mobile: 'S', tablet: 'M', desktop: 'L'),
        'M',
      );
    });

    test('resolveFor keys off an existing size', () {
      expect(
        RushSetup.resolveFor(
          type: RushDeviceType.desktop,
          mobile: 'S',
          tablet: 'M',
          desktop: 'L',
        ),
        'L',
      );
    });
  });
}
