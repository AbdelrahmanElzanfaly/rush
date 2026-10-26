/// Responsive layout primitives for Flutter.
///
/// Rush classifies the available width into three [RushDeviceType] classes and
/// gives you three ways to branch on it:
///
///  * [RushWidget] — swap between up to three whole layouts.
///  * [RushBuilder] — one callback that receives the resolved size.
///  * [RushBuildContext] — `context.isMobile`, `context.rushValue(...)`.
///
/// The two settings that drive all of it — [RushBreakpoints] and
/// [RushScreenMap] — are grouped in a [RushConfig]. Set one globally with
/// [RushSetup.init], or override either knob on a single widget. Configuration
/// is optional; [RushConfig.standard] is 768 / 1200 with no remapping.
///
/// ```dart
/// void main() {
///   RushSetup.init(const RushConfig(
///     breakpoints: RushBreakpoints(tablet: 600, desktop: 1024),
///     // No tablet design yet — tablet screens render the desktop layout.
///     screens: RushScreenMap(tablet: RushDeviceType.desktop),
///   ));
///   runApp(const MyApp());
/// }
/// ```
library;

// Core: the values that describe a responsive configuration.
export 'src/core/rush_breakpoints.dart';
export 'src/core/rush_config.dart';
export 'src/core/rush_screen_map.dart';
export 'src/core/rush_device_type.dart';
// Extensions: the same decisions, reached from a BuildContext.
export 'src/extensions/rush_context.dart';
// The global configuration holder.
export 'src/rush_setup.dart';
// Widgets: the things you actually put in a build method.
export 'src/widgets/rush_builder.dart';
export 'src/widgets/rush_widget.dart';
