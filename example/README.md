# rush_example

A one-screen demo of the [rush](../) package.

```sh
cd example
flutter run -d macos   # or chrome, windows, linux
```

Resize the window and watch the layout move between the three screen classes.
The demo covers all four entry points:

| Where | What it shows |
|---|---|
| `main` | a screen map sending tablet screens to the mobile layout, since this demo has no tablet design |
| `HomePage` | `RushWidget` swapping whole layouts |
| `_SizeBanner` | `context.rushDevice` vs `context.rushDetectedDevice`, `rushValue`, `rushWidth` |
| `_Sidebar` | a `RushBuilder` in a 260px panel reporting `mobile` on a desktop, because it measures its own box |
| `_Content` | `RushDeviceType.pick` choosing a column count |

Between 700px and 1100px the banner reads `detected tablet → renders mobile`,
which is the remapping at work. Delete `screens:` from `main()` to see
the difference.

Run it on a phone-sized window to see the single-column layout, then widen past
1100px for the split view.
