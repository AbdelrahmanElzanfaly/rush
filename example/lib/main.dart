import 'package:flutter/material.dart';
import 'package:rush/rush.dart';

void main() {
  // Optional — Rush defaults to 768 / 1200 and no remapping if you skip this.
  // Both knobs travel together in one RushConfig.
  RushSetup.init(
    const RushConfig(
      breakpoints: RushBreakpoints(tablet: 700, desktop: 1100),
      // There is no tablet design in this demo, so tablet screens render the
      // mobile layout. Delete this line once a real tablet layout exists.
      screens: RushScreenMap(tablet: RushDeviceType.mobile),
    ),
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rush example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

/// Resize the window (or rotate the device) to move between the three
/// layouts.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rush')),
      // 1. RushWidget — two layouts, and a screen map in main() sending
      //    tablet screens to the mobile one.
      body: const RushWidget(
        mobile: _StackedLayout(),
        desktop: _SplitLayout(),
      ),
    );
  }
}

class _StackedLayout extends StatelessWidget {
  const _StackedLayout();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SizeBanner(),
        SizedBox(height: 16),
        _Sidebar(),
        SizedBox(height: 16),
        // Inside a ListView, so the grid must shrink-wrap rather than scroll.
        _Content(shrinkWrap: true),
      ],
    );
  }
}

class _SplitLayout extends StatelessWidget {
  const _SplitLayout();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SizeBanner(),
          SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 260, child: _Sidebar()),
                SizedBox(width: 16),
                Expanded(child: _Content()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the current screen class, read straight off the context.
class _SizeBanner extends StatelessWidget {
  const _SizeBanner();

  @override
  Widget build(BuildContext context) {
    // 2. Context extensions — one-off decisions, keyed off the window.
    //    rushDevice is the slot being rendered; rushDetectedDevice is the raw
    //    screen class, so on a tablet-width window these disagree.
    final size = context.rushDevice;
    final detected = context.rushDetectedDevice;
    final label = context.rushValue(
      mobile: 'one column',
      desktop: 'split view',
    );
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsets.all(context.rushValue(mobile: 12.0, desktop: 20.0)),
        child: Text(
          'detected ${detected.name} → renders ${size.name}: $label\n'
          'window ${context.rushWidth.toStringAsFixed(0)}px · '
          'breakpoints ${RushSetup.startTabletSize.toStringAsFixed(0)} / '
          '${RushSetup.startDesktopSize.toStringAsFixed(0)} · '
          '${RushSetup.screens}',
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // 3. RushBuilder inside a narrow box — note it reports `mobile`
            //    even on a desktop, because it measures its own constraints
            //    rather than the window.
            RushBuilder(
              builder: (context, size, constraints) => Text(
                'this panel is ${constraints.maxWidth.toStringAsFixed(0)}px '
                'wide, so Rush calls it ${size.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({this.shrinkWrap = false});

  /// Set when this sits inside another scrollable.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    // 4. RushBuilder for a value that varies smoothly with the layout.
    return RushBuilder(
      builder: (context, size, constraints) {
        final columns = size.pick(mobile: 1, tablet: 2, desktop: 3);
        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          children: List.generate(
            6,
            (i) => Card(
              child: Center(child: Text('item ${i + 1}')),
            ),
          ),
        );
      },
    );
  }
}
