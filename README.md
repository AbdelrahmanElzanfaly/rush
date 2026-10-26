# rush

Responsive layout primitives for Flutter. Classify the available width into
three device classes and branch on it — without writing the same
`LayoutBuilder` ladder in every file.

```dart
RushWidget(
  mobile: MobileHome(),
  tablet: TabletHome(),
  desktop: DesktopHome(),
)
```

No setup required: Rush works out of the box with 768 / 1200 breakpoints.

## Install

```yaml
dependencies:
  rush:
    git: https://github.com/khaledSayedAbdellah/rush.git
```

```dart
import 'package:rush/rush.dart';
```

## Device classes

A width maps to a [`RushDeviceType`] through two thresholds, both inclusive
lower bounds:

| width | class |
|---|---|
| `[0, tablet)` | `RushDeviceType.mobile` |
| `[tablet, desktop)` | `RushDeviceType.tablet` |
| `[desktop, ∞)` | `RushDeviceType.desktop` |

With the defaults, `767` is mobile, `768` is tablet, `1200` is desktop.

## Configuring

Rush has exactly two knobs, and they travel together in a `RushConfig`:

| knob | type | question it answers |
|---|---|---|
| `breakpoints` | `RushBreakpoints` | at which widths does the screen class change? |
| `screens` | `RushScreenMap` | which layout does each screen class render? |

Set it globally, once, before `runApp`:

```dart
void main() {
  RushSetup.init(const RushConfig(
    breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
  ));
  runApp(const MyApp());
}
```

Both fields have defaults, so you only name what you are changing, and the
whole thing is `const`. There are presets for the common cases:

```dart
RushSetup.init(RushConfig.material3);                     // 600 / 840
RushSetup.init(const RushConfig(breakpoints: RushBreakpoints.material3));
```

To change one knob and keep the other, copy the current config:

```dart
RushSetup.init(RushSetup.config.copyWith(
  screens: RushScreenMap.alwaysMobile,
));
```

`init` is optional and idempotent — call it as often as you like, including
after a hot restart. Invalid bounds (`tablet >= desktop`, zero, infinity) throw
an `ArgumentError` rather than silently producing a range no width can match.

The configuration is app-wide. Rush widgets read it at build time, so there is
nothing to pass down and nothing to keep in sync.

## Borrowing another size's layout

Breakpoints answer *what size is this screen*. Which layout that size should
render is a separate question, and you can answer it yourself.

The usual reason is a design that does not exist yet. If there is no tablet
layout, say which one to use in its place:

```dart
RushSetup.init(const RushConfig(
  screens: RushScreenMap(tablet: RushDeviceType.desktop),
));
```

Tablet screens now render the `desktop` layout, and keep doing so until you
write a real tablet design and delete the line. Read each field as *"screens
of this size render that slot"*. All three default to themselves, so you only
name the ones you are redirecting.

`RushScreenMap.alwaysMobile` collapses everything onto the mobile layout —
handy when only the phone design exists. `RushScreenMap.identity` is the
default, and undoes an inherited mapping.

Mapping and the fallback chain compose, in that order: the map decides which
slot Rush asks for, and the chain only runs if that slot turns out to be
empty. The map is the deliberate choice; the chain is the safety net.

`context.rushDevice` reports the slot *after* mapping, so it agrees with what
`RushWidget` renders. When you want the raw classification, use
`context.rushDetectedDevice`.

## The four ways to use it

### `RushWidget` — swap whole layouts

```dart
RushWidget(
  mobile: MobileHome(),
  desktop: DesktopHome(),
)
```

Every slot is optional. When the slot for the current class is missing, Rush
renders the closest one you did supply, preferring a **narrower** layout —
narrow layouts survive wide screens, wide layouts overflow narrow ones:

| resolved | tries, in order |
|---|---|
| mobile | mobile → tablet → desktop |
| tablet | tablet → mobile → desktop |
| desktop | desktop → tablet → mobile |

So the snippet above renders `MobileHome` on tablet screens. `RushWidget` with
no slots at all is a programming error and asserts in debug.

### `RushBuilder` — one callback

Better when the branches share code and differ by a value rather than a whole
tree:

```dart
RushBuilder(
  builder: (context, type, constraints) => GridView.count(
    crossAxisCount: type.pick(mobile: 1, tablet: 2, desktop: 4),
    children: tiles,
  ),
)
```

You get the resolved `type` **and** the real `constraints`, so you can mix
coarse branching with exact measurements.

### Context extensions — one-off decisions

```dart
Padding(
  padding: EdgeInsets.all(context.rushValue(mobile: 12.0, desktop: 24.0)),
  child: context.isDesktop ? const Sidebar() : const Drawer(),
)
```

Also available: `context.rushDevice`, `context.rushDetectedDevice`,
`context.maybeRushDevice`, `context.isMobile` / `isTablet` /
`isDesktop`, `context.rushWidth`.

In `rushValue`, omitted values fall back to the next narrower one, so
`context.rushValue(mobile: 8, desktop: 32)` returns `8` on tablet screens.

### Picking a value — not just widgets

Works for `Size`, `EdgeInsets`, `int`, `TextStyle`, anything. Two entry
points, depending on what you are holding:

```dart
// You have a RushDeviceType already — from RushBuilder, say.
final columns = type.pick(mobile: 1, tablet: 2, desktop: 4);

// You have a width, and want it classified first.
final card = RushSetup.resolve<Size>(
  width: constraints.maxWidth,
  mobile: const Size(320, 180),
  tablet: const Size(480, 270),
  desktop: const Size(640, 360),
);
```

`RushSetup.resolve` is a shorthand for `RushSetup.config.resolve`; call the
latter directly when you hold a `RushConfig` that is not the global one.

## Which width gets measured?

This trips people up, so Rush is explicit about it.

- **`RushWidget` and `RushBuilder`** measure the **incoming constraints**. A
  `RushWidget` inside a 300px sidebar reports `mobile` even on a 4K monitor,
  which is almost always what you want. Pass `useWindowWidth: true` to opt out.
- **The context extensions** measure the **window**, via `MediaQuery`.

If the incoming constraints are horizontally unbounded — inside a `Row`, a
horizontal `ListView`, an unconstrained `SingleChildScrollView` — Rush falls
back to the window width instead of classifying an infinite width as desktop.

## Testing

`RushSetup` is global state, so reset it between tests:

```dart
tearDown(RushSetup.reset);
```

To drive a specific width, set the test view size:

```dart
tester.view.devicePixelRatio = 1.0;
tester.view.physicalSize = const Size(1600, 900);
addTearDown(tester.view.reset);
```

`RushWidget.resolveFor(type)` and `RushBreakpoints.typeOf(width)` are pure, so
most branch logic can be tested without pumping a widget at all.

## Example

A runnable demo lives in [`example/`](example):

```sh
cd example && flutter run
```

## Contributing

Issues and pull requests are welcome at
[github.com/khaledSayedAbdellah/rush](https://github.com/khaledSayedAbdellah/rush).
Please run `flutter analyze` and `flutter test` before opening a PR; both must
be clean.

## License

MIT — see [LICENSE](LICENSE).

[`RushDeviceType`]: lib/src/core/rush_device_type.dart
