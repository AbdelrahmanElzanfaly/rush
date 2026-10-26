import 'package:flutter_test/flutter_test.dart';
import 'package:rush/rush.dart';

void main() {
  group('RushBreakpoints.typeOf', () {
    const b = RushBreakpoints.standard;

    test('classifies widths below the tablet bound as mobile', () {
      expect(b.typeOf(0), RushDeviceType.mobile);
      expect(b.typeOf(320), RushDeviceType.mobile);
      expect(b.typeOf(767.9), RushDeviceType.mobile);
    });

    test('treats the tablet bound as inclusive', () {
      // The pre-0.1.0 implementation used `<=` here and classified exactly
      // 768 as mobile, off by one against the documented range.
      expect(b.typeOf(768), RushDeviceType.tablet);
    });

    test('classifies widths between the bounds as tablet', () {
      expect(b.typeOf(768), RushDeviceType.tablet);
      expect(b.typeOf(1024), RushDeviceType.tablet);
      expect(b.typeOf(1199.9), RushDeviceType.tablet);
    });

    test('treats the desktop bound as inclusive', () {
      expect(b.typeOf(1200), RushDeviceType.desktop);
    });

    test('classifies widths above the desktop bound as desktop', () {
      expect(b.typeOf(1201), RushDeviceType.desktop);
      expect(b.typeOf(4096), RushDeviceType.desktop);
    });

    test('degrades on hostile input instead of throwing', () {
      expect(b.typeOf(-100), RushDeviceType.mobile);
      expect(b.typeOf(double.nan), RushDeviceType.mobile);
      expect(b.typeOf(double.negativeInfinity), RushDeviceType.mobile);
      expect(b.typeOf(double.infinity), RushDeviceType.desktop);
    });

    test('honours custom bounds', () {
      const custom = RushBreakpoints(tablet: 600, desktop: 1024);
      expect(custom.typeOf(599), RushDeviceType.mobile);
      expect(custom.typeOf(600), RushDeviceType.tablet);
      expect(custom.typeOf(1023), RushDeviceType.tablet);
      expect(custom.typeOf(1024), RushDeviceType.desktop);
    });

    test('material3 preset matches the window size classes', () {
      const m3 = RushBreakpoints.material3;
      expect(m3.typeOf(599), RushDeviceType.mobile);
      expect(m3.typeOf(600), RushDeviceType.tablet);
      expect(m3.typeOf(839), RushDeviceType.tablet);
      expect(m3.typeOf(840), RushDeviceType.desktop);
    });
  });

  group('RushBreakpoints validation', () {
    // An invalid pair is rejected twice over: the constructor asserts (a
    // compile-time error for `const` instances, an AssertionError in debug)
    // and validate() throws ArgumentError, which survives into release where
    // assertions are stripped. Tests run with assertions on, so the assertion
    // is what fires here — accept either so the suite documents the contract
    // rather than the build mode.
    final throwsInvalidBreakpoints =
        throwsA(anyOf(isA<AssertionError>(), isA<ArgumentError>()));

    // Built through a function so the arguments are not compile-time
    // constants: a `const RushBreakpoints` with bad bounds would not compile
    // at all, which is the point, but it cannot be asserted on at runtime.
    RushBreakpoints make(double tablet, double desktop) =>
        RushBreakpoints(tablet: tablet, desktop: desktop);

    test('accepts a sane pair', () {
      expect(make(600, 1024).validate, returnsNormally);
    });

    test('rejects inverted bounds', () {
      expect(() => make(1400, 1200), throwsInvalidBreakpoints);
    });

    test('rejects equal bounds, which would empty the tablet range', () {
      expect(() => make(900, 900), throwsInvalidBreakpoints);
    });

    test('rejects a non-positive tablet bound', () {
      expect(() => make(0, 1200), throwsInvalidBreakpoints);
      expect(() => make(-10, 1200), throwsInvalidBreakpoints);
    });

    test('rejects a non-finite bound', () {
      expect(() => make(double.infinity, 1200), throwsInvalidBreakpoints);
      expect(() => make(768, double.nan), throwsInvalidBreakpoints);
    });
  });

  group('RushBreakpoints value semantics', () {
    test('equal bounds compare equal and hash alike', () {
      const a = RushBreakpoints(tablet: 600, desktop: 1024);
      const b = RushBreakpoints(tablet: 600, desktop: 1024);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different bounds are not equal', () {
      expect(
        const RushBreakpoints(tablet: 600, desktop: 1024),
        isNot(const RushBreakpoints(tablet: 700, desktop: 1024)),
      );
    });

    test('copyWith replaces only the named field', () {
      const a = RushBreakpoints(tablet: 600, desktop: 1024);
      expect(a.copyWith(desktop: 1400),
          const RushBreakpoints(tablet: 600, desktop: 1400));
      expect(a.copyWith().tablet, 600);
    });

    test('toString is readable', () {
      expect(
        const RushBreakpoints(tablet: 600, desktop: 1024).toString(),
        contains('600'),
      );
    });
  });
}
