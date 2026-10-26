import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rush/rush.dart';

import '../support/pump.dart';

/// A builder that renders the resolved size as text so tests can read it.
Widget sizeProbe({bool useWindowWidth = false}) => RushBuilder(
      useWindowWidth: useWindowWidth,
      builder: (context, size, constraints) => Text(size.name),
    );

void main() {
  tearDown(RushSetup.reset);

  group('RushBuilder', () {
    testWidgets('reports the size for the available width', (tester) async {
      await pumpAtWidth(tester, 400, sizeProbe());
      expect(find.text('mobile'), findsOneWidget);

      await pumpAtWidth(tester, 900, sizeProbe());
      expect(find.text('tablet'), findsOneWidget);

      await pumpAtWidth(tester, 1400, sizeProbe());
      expect(find.text('desktop'), findsOneWidget);
    });

    testWidgets('passes the real constraints through', (tester) async {
      late BoxConstraints seen;
      await pumpAtWidth(
        tester,
        1600,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 250,
            height: 100,
            child: RushBuilder(
              builder: (context, size, constraints) {
                seen = constraints;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(seen.maxWidth, 250);
      expect(seen.maxHeight, 100);
    });

    testWidgets('rebuilds when the width crosses a breakpoint',
        (tester) async {
      var builds = 0;
      Widget counter() => RushBuilder(
            builder: (context, size, constraints) {
              builds++;
              return Text(size.name);
            },
          );

      await pumpAtWidth(tester, 400, counter());
      expect(find.text('mobile'), findsOneWidget);
      final afterFirst = builds;

      await pumpAtWidth(tester, 1400, counter());
      expect(find.text('desktop'), findsOneWidget);
      expect(builds, greaterThan(afterFirst));
    });

    testWidgets('honours the configured breakpoints', (tester) async {
      RushSetup.init(RushConfig.material3);
      await pumpAtWidth(tester, 700, sizeProbe());
      expect(find.text('tablet'), findsOneWidget);

      RushSetup.init(
        const RushConfig(breakpoints: RushBreakpoints(tablet: 1000)),
      );
      await pumpAtWidth(tester, 700, sizeProbe());
      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('measures the enclosing box by default', (tester) async {
      await pumpAtWidth(tester, 1600, boxed(300, sizeProbe()));
      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('useWindowWidth measures the window instead', (tester) async {
      await pumpAtWidth(
        tester,
        1600,
        boxed(300, sizeProbe(useWindowWidth: true)),
      );
      expect(find.text('desktop'), findsOneWidget);
    });
  });

  group('screen remapping', () {
    testWidgets('the builder receives the remapped slot', (tester) async {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await pumpAtWidth(tester, 1000, sizeProbe());
      expect(find.text('desktop'), findsOneWidget);
    });

    testWidgets('a downward remap reaches the builder too', (tester) async {
      RushSetup.init(
        const RushConfig(
          screens: RushScreenMap(desktop: RushDeviceType.mobile),
        ),
      );
      await pumpAtWidth(tester, 1600, sizeProbe());
      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('remapping composes with custom breakpoints', (tester) async {
      RushSetup.init(
        const RushConfig(
          breakpoints: RushBreakpoints.material3,
          screens: RushScreenMap(tablet: RushDeviceType.desktop),
        ),
      );
      await pumpAtWidth(tester, 700, sizeProbe());
      expect(find.text('desktop'), findsOneWidget);
    });
  });

  group('RushBuilder.resolveWidth', () {
    testWidgets('prefers finite constraints', (tester) async {
      late double width;
      await withContext(tester, 1600, (context) {
        width = RushBuilder.resolveWidth(
          context,
          const BoxConstraints(maxWidth: 500),
        );
      });
      expect(width, 500);
    });

    testWidgets('falls back to the window when unbounded', (tester) async {
      late double width;
      await withContext(tester, 1600, (context) {
        width = RushBuilder.resolveWidth(context, const BoxConstraints());
      });
      expect(width, 1600);
    });

    testWidgets('prefers the window when asked, even if bounded',
        (tester) async {
      late double width;
      await withContext(tester, 1600, (context) {
        width = RushBuilder.resolveWidth(
          context,
          const BoxConstraints(maxWidth: 500),
          useWindowWidth: true,
        );
      });
      expect(width, 1600);
    });

    testWidgets('returns zero with no MediaQuery ancestor', (tester) async {
      late double width;
      await withoutMediaQuery(tester, (context) {
        width = RushBuilder.resolveWidth(
          context,
          const BoxConstraints(),
          useWindowWidth: true,
        );
      });
      expect(width, 0);
    });
  });
}
