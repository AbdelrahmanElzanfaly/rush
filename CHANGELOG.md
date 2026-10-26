# Changelog

## 0.4.0

Renaming release. `small` / `medium` / `large` become `mobile` / `tablet` /
`desktop` everywhere. No behaviour changes — the same widths resolve to the
same layouts, and the defaults are still 768 / 1200.

### Changed

- **`RushScreenSize` is now `RushDeviceType`**, with values `mobile`,
  `tablet` and `desktop`. The file moved to
  `lib/src/core/rush_device_type.dart`.

  ```dart
  // before
  RushWidget(small: Phone(), medium: Tab(), large: Desk())

  // after
  RushWidget(mobile: Phone(), tablet: Tab(), desktop: Desk())
  ```

  These are names for width bands, not detected hardware. Rush never asks the
  platform what it is running on: a desktop window dragged narrow is
  `mobile`, and a `RushWidget` inside a 300px panel is `mobile` on a 4K
  monitor. The names describe the layout you would design for that much room.

- `RushBreakpoints(medium:, large:)` → `RushBreakpoints(tablet:, desktop:)`,
  and `defaultMedium` / `defaultLarge` → `defaultTablet` / `defaultDesktop`.
- `RushScreenMap(small:, medium:, large:)` →
  `RushScreenMap(mobile:, tablet:, desktop:)`, and `alwaysSmall` →
  `alwaysMobile`.
- `RushSetup.startMediumSize` / `startLargeSize` → `startTabletSize` /
  `startDesktopSize`.
- `RushSetup.sizeOf` → `typeOf` and `detectedSizeOf` → `detectedTypeOf`, since
  they return a device class rather than a size. `RushSetup.of` and
  `detectedOf` keep their names.
- `RushSetup.resolveFor(size:)` → `resolveFor(type:)`.
- Every `small:` / `medium:` / `large:` argument — on `RushWidget`,
  `RushDeviceType.pick`, `RushConfig.resolve`, `RushSetup.resolve` and
  `context.rushValue` — is now `mobile:` / `tablet:` / `desktop:`.
- Context getters: `isSmallScreen` / `isMediumScreen` / `isLargeScreen` →
  `isMobile` / `isTablet` / `isDesktop`; `rushSize` → `rushDevice`;
  `maybeRushSize` → `maybeRushDevice`; `rushDetectedSize` →
  `rushDetectedDevice`.
- The `RushBuilder` callback's second argument is named `type` rather than
  `size` in the signature and docs. Positional, so existing lambdas are
  unaffected.

`RushScreenMap` and `RushConfig.screens` keep their names — they still map a
detected class onto a layout slot.

## 0.3.0

### Removed

- **`breakpoints:` and `screens:` on `RushWidget` and `RushBuilder`.** They
  let a single widget depart from the app-wide configuration, but scoping a
  whole subtree meant repeating the argument on every Rush widget inside it —
  the wrong mechanism for the job. Configuration is now app-wide only, set
  once with `RushSetup.init`:

  ```dart
  // before
  RushWidget(
    breakpoints: const RushBreakpoints(medium: 500, large: 900),
    small: Compact(),
    large: Wide(),
  )

  // after
  RushSetup.init(const RushConfig(
    breakpoints: RushBreakpoints(medium: 500, large: 900),
  ));
  RushWidget(small: Compact(), large: Wide())
  ```

  `useWindowWidth` is unaffected. If per-subtree configuration turns out to be
  needed, the right shape for it is an inherited widget rather than a
  parameter on every call site.

## 0.2.0

Organisational release. No behaviour changes — the same widths resolve to the
same layouts — but the configuration is grouped into one object and the source
is grouped into folders.

### Changed

- **`RushSetup.init` takes a single [RushConfig]** instead of five loose
  parameters. The two settings that belong together now travel together, and
  the whole configuration is `const`, comparable and printable.

  ```dart
  // before
  RushSetup.init(startMediumSize: 600, mediumScreens: RushScreenSize.large);

  // after
  RushSetup.init(const RushConfig(
    breakpoints: RushBreakpoints(medium: 600),
    screens: RushScreenMap(medium: RushScreenSize.large),
  ));
  ```

- `RushSetup.configure(breakpoints:, screens:)` is gone; one entry point is
  enough now that partial updates read naturally as
  `RushSetup.init(RushSetup.config.copyWith(screens: ...))`.
- **`RushSetup` is now a thin holder.** The rules moved to where the data
  lives: classification to `RushConfig`, value-picking to
  `RushScreenSize.pick`. Everything still on `RushSetup` — `sizeOf`, `of`,
  `resolve`, `resolveFor` — is a documented one-line shorthand, so no call
  site breaks.
- **`lib/src` is grouped into folders**: `core/` (screen size, breakpoints,
  screen map, config), `widgets/` (`RushWidget`, `RushBuilder`),
  `extensions/` (the `BuildContext` helpers). Import
  `package:rush/rush.dart` as before; nothing moved in the public API.
- Members within each class follow one order: constructors, static presets,
  fields, derived getters, methods, overrides. `RushSetup` is sectioned by
  what you are doing — reading config, changing it, classifying a width,
  picking a value.
- The test suite mirrors the new folder layout.

### Added

- `RushConfig`, holding `breakpoints` and `screens` together, with
  `slotForWidth`, `detectedForWidth`, `resolve`, `copyWith`, `validate`, `==`
  and the `standard` and `material3` presets.
- `RushScreenSize.pick`, a pure three-way choice on a size you already hold.
  `RushSetup.resolveFor` now delegates to it.

## 0.1.0

First usable release. This is a breaking rewrite of the 0.0.1 prototype; the
`RushScreenSize` remapping layer is gone and `RushWidget`'s parameters have
been renamed.

### Fixed

- **`RushWidget` is now actually exported.** `package:rush/rush.dart` never
  exported `responsive_layout.dart`, so importing the library gave you the
  enum and the setup class but not the widget.
- **`RushSetup.init` can be called more than once.** The breakpoints were
  `late final` statics, so a second call — a hot restart, a second test —
  threw `LateInitializationError`.
- **Rush works before `init` is called.** The configuration fields were `late`
  with no value, so any read before `init` threw instead of using the
  documented 768 / 1200 defaults.
- **Breakpoint bounds are validated.** `medium >= large` used to produce a
  medium range no width could ever match. It now throws an `ArgumentError`,
  and fails at compile time for `const RushBreakpoints`.
- **Off-by-one at the boundary.** A width of exactly `768` was classified as
  small; the lower bound is now inclusive, as documented.
- **No more hardcoded English error text in production.** A missing slot used
  to render `Text("the providing screens not suitable for your rush.init
  method")`. Missing slots now fall back to the nearest supplied layout, and
  supplying no slots at all asserts in debug.
- Removed the unreachable branch and dead `return` at the end of the layout
  builder.

### Added

- `RushScreenMap`, a typed home for the screen-to-slot redirection that 0.0.1
  configured through `RushSetup.init(largeScreens:, mediumScreens:,
  smallScreens:)`. Those parameters still work and mean what they always
  meant: *screens of this size render that slot*. What changed is that the
  mapping is now a value type with `==`, `copyWith` and the `identity` and
  `alwaysSmall` presets, it can be overridden per subtree via `screens:` on
  `RushWidget` and `RushBuilder`, and it is no longer read back through three
  loose `RushScreenSize` getters.
- `RushBuilder`, a callback that receives the resolved `RushScreenSize` and
  the real `BoxConstraints`.
- `RushBreakpoints`, an immutable value type with `==`, `hashCode`,
  `copyWith`, `validate`, and the `standard` and `material3` presets.
- Per-subtree breakpoint overrides via `breakpoints:` on `RushWidget` and
  `RushBuilder`.
- `BuildContext` extensions: `rushSize`, `rushDetectedSize`, `maybeRushSize`,
  `isSmallScreen`, `isMediumScreen`, `isLargeScreen`, `rushWidth`,
  `rushValue`.
- `RushScreenSize.of(context)`, `RushSetup.of(context)`, `RushSetup.sizeOf`,
  `RushSetup.detectedSizeOf`, `RushSetup.detectedOf`, `RushSetup.resolve`,
  `RushSetup.resolveFor`, `RushSetup.configure`, `RushSetup.reset`.
- `RushScreenSize` helpers: `isSmall` / `isMedium` / `isLarge`, `isAtLeast`,
  `isAtMost`, `fallbackOrder`.
- `useWindowWidth` to measure the window rather than the enclosing box, plus
  an automatic window-width fallback when constraints are horizontally
  unbounded.
- `debugFillProperties` on `RushWidget`, so it reads sensibly in the widget
  inspector.
- A test suite covering breakpoint boundaries, the fallback chain, repeated
  initialisation and unbounded constraints.
- A runnable example app in `example/`.
- MIT license, real README, dartdoc on every public member.

### Changed

- `RushWidget`'s `smallScreen` / `mediumScreen` / `largeScreen` parameters are
  now `small` / `medium` / `large`.
- `RushSetup.getSize(...)` is replaced by the generic
  `RushSetup.resolve<T>(...)`, which no longer requires a manual `maxWidth`
  when used through `RushBuilder`.
- `RushSetup.largeScreens` / `mediumScreens` / `smallScreens` — the three
  getters that returned a `RushScreenSize` — are replaced by the single
  `RushSetup.screens`, which returns a `RushScreenMap`. The `init` parameters
  of the same names are unchanged.
- `RushSetup.sizeOf` and `RushSetup.of` return the slot *after* mapping, which
  is what callers almost always want. `detectedSizeOf` and `detectedOf` return
  the raw classification. With no mapping configured the two are identical.
- Minimum SDK is now Dart 3.0 / Flutter 3.10.
- `flutter_lints` upgraded to 6.x, with additional analyzer rules enabled.

## 0.0.1

- Initial prototype.
