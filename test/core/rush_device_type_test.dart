import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush/rush.dart';

void main() {
  group('RushDeviceType', () {
    test('exposes convenience predicates', () {
      expect(RushDeviceType.mobile.isMobile, isTrue);
      expect(RushDeviceType.mobile.isDesktop, isFalse);
      expect(RushDeviceType.desktop.isDesktop, isTrue);
    });

    test('orders mobile < tablet < desktop', () {
      expect(RushDeviceType.desktop.isAtLeast(RushDeviceType.tablet), isTrue);
      expect(RushDeviceType.mobile.isAtLeast(RushDeviceType.tablet), isFalse);
      expect(RushDeviceType.mobile.isAtMost(RushDeviceType.desktop), isTrue);
      expect(RushDeviceType.tablet.isAtLeast(RushDeviceType.tablet), isTrue);
    });

    test('fallback order starts with itself and covers every size', () {
      for (final size in RushDeviceType.values) {
        expect(size.fallbackOrder.first, size);
        expect(size.fallbackOrder.toSet(), RushDeviceType.values.toSet());
      }
    });

    test('tablet and desktop degrade to the narrower layout first', () {
      expect(RushDeviceType.tablet.fallbackOrder[1], RushDeviceType.mobile);
      expect(RushDeviceType.desktop.fallbackOrder[1], RushDeviceType.tablet);
      // mobile has nothing narrower, so it climbs.
      expect(RushDeviceType.mobile.fallbackOrder[1], RushDeviceType.tablet);
    });
  });

  group('pick', () {
    test('returns the value for this size', () {
      expect(
        RushDeviceType.mobile.pick(mobile: 'S', tablet: 'M', desktop: 'L'),
        'S',
      );
      expect(
        RushDeviceType.tablet.pick(mobile: 'S', tablet: 'M', desktop: 'L'),
        'M',
      );
      expect(
        RushDeviceType.desktop.pick(mobile: 'S', tablet: 'M', desktop: 'L'),
        'L',
      );
    });

    test('is generic over the value type', () {
      expect(
        RushDeviceType.desktop.pick(mobile: 1, tablet: 2, desktop: 4),
        4,
      );
      expect(
        RushDeviceType.tablet.pick(
          mobile: const EdgeInsets.all(8),
          tablet: const EdgeInsets.all(16),
          desktop: const EdgeInsets.all(32),
        ),
        const EdgeInsets.all(16),
      );
    });

    test('agrees with RushSetup.resolveFor, which delegates to it', () {
      for (final size in RushDeviceType.values) {
        expect(
          RushSetup.resolveFor(
            type: size,
            mobile: 'S',
            tablet: 'M',
            desktop: 'L',
          ),
          size.pick(mobile: 'S', tablet: 'M', desktop: 'L'),
        );
      }
    });
  });
}
