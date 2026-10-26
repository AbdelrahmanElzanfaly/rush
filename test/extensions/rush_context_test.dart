import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush/rush.dart';

import '../support/pump.dart';

void main() {
  tearDown(RushSetup.reset);

  group('rushDevice', () {
    testWidgets('classifies the window width', (tester) async {
      await withContext(
        tester,
        400,
        (c) => expect(c.rushDevice.isMobile, isTrue),
      );
      await withContext(
          tester, 900, (c) => expect(c.rushDevice.isTablet, isTrue));
      await withContext(
          tester, 1400, (c) => expect(c.rushDevice.isDesktop, isTrue));
    });

    testWidgets('RushDeviceType.of and RushSetup.of agree', (tester) async {
      await withContext(tester, 1400, (c) {
        expect(RushDeviceType.of(c), RushDeviceType.desktop);
        expect(RushSetup.of(c), RushDeviceType.desktop);
        expect(c.rushDevice, RushDeviceType.desktop);
      });
    });

    testWidgets('follows the configured breakpoints', (tester) async {
      RushSetup.init(
        RushSetup.config.copyWith(breakpoints: RushBreakpoints.material3),
      );
      await withContext(
          tester, 700, (c) => expect(c.rushDevice, RushDeviceType.tablet));
    });

    testWidgets('rushDevice reports the remapped slot', (tester) async {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await withContext(
        tester,
        1000,
        (c) => expect(c.rushDevice, RushDeviceType.desktop),
      );
    });

    testWidgets('rushDetectedDevice ignores the remapping', (tester) async {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await withContext(tester, 1000, (c) {
        expect(c.rushDevice, RushDeviceType.desktop);
        expect(c.rushDetectedDevice, RushDeviceType.tablet);
      });
    });

    testWidgets('rushValue follows the remapping', (tester) async {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await withContext(
        tester,
        1000,
        (c) => expect(c.rushValue(mobile: 1, tablet: 2, desktop: 4), 4),
      );
    });

    testWidgets('maybeRushDevice is null with no MediaQuery', (tester) async {
      RushDeviceType? size = RushDeviceType.desktop;
      await withoutMediaQuery(tester, (c) => size = c.maybeRushDevice);
      expect(size, isNull);
    });
  });

  group('predicates', () {
    testWidgets('exactly one is true at a time', (tester) async {
      for (final entry in {400.0: 'mobile', 900.0: 'tablet', 1400.0: 'desktop'}
          .entries) {
        await withContext(tester, entry.key, (c) {
          final flags = [c.isMobile, c.isTablet, c.isDesktop];
          expect(flags.where((f) => f).length, 1,
              reason: 'at width ${entry.key} (${entry.value})');
        });
      }
    });

    testWidgets('rushWidth reports the window width', (tester) async {
      await withContext(tester, 1234, (c) => expect(c.rushWidth, 1234));
    });
  });

  group('rushValue', () {
    testWidgets('picks the value for the current size', (tester) async {
      await withContext(
        tester,
        400,
        (c) => expect(c.rushValue(mobile: 1, tablet: 2, desktop: 4), 1),
      );
      await withContext(
        tester,
        900,
        (c) => expect(c.rushValue(mobile: 1, tablet: 2, desktop: 4), 2),
      );
      await withContext(
        tester,
        1400,
        (c) => expect(c.rushValue(mobile: 1, tablet: 2, desktop: 4), 4),
      );
    });

    testWidgets('omitted values fall back to the next narrower one',
        (tester) async {
      await withContext(tester, 900, (c) => expect(c.rushValue(mobile: 8), 8));
      await withContext(tester, 1400, (c) => expect(c.rushValue(mobile: 8), 8));
      await withContext(
        tester,
        1400,
        (c) => expect(c.rushValue(mobile: 8, tablet: 16), 16),
      );
      await withContext(
        tester,
        900,
        (c) => expect(c.rushValue(mobile: 8, desktop: 32), 8),
      );
    });

    testWidgets('is generic over the value type', (tester) async {
      await withContext(tester, 1400, (c) {
        expect(
          c.rushValue(
            mobile: const EdgeInsets.all(8),
            desktop: const EdgeInsets.all(32),
          ),
          const EdgeInsets.all(32),
        );
        expect(c.rushValue(mobile: Axis.vertical, desktop: Axis.horizontal),
            Axis.horizontal);
      });
    });
  });
}
