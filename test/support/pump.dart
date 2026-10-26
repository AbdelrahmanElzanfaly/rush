import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a window [width] logical pixels wide.
///
/// Sets both the test view (which drives the root constraints, and therefore
/// anything measuring `BoxConstraints`) and an explicit `MediaQuery` (which
/// drives anything measuring the window), so the two always agree.
Future<void> pumpAtWidth(
  WidgetTester tester,
  double width,
  Widget child, {
  double height = 800,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: Directionality(textDirection: TextDirection.ltr, child: child),
    ),
  );
}

/// Constrains [child] to [width], regardless of how wide the window is.
Widget boxed(double width, Widget child) => Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    );

/// Runs [body] with a [BuildContext] under a window [width] wide.
Future<void> withContext(
  WidgetTester tester,
  double width,
  void Function(BuildContext context) body,
) async {
  await pumpAtWidth(
    tester,
    width,
    Builder(
      builder: (context) {
        body(context);
        return const SizedBox();
      },
    ),
  );
}

/// Runs [body] with a [BuildContext] that has no `MediaQuery` ancestor.
Future<void> withoutMediaQuery(
  WidgetTester tester,
  void Function(BuildContext context) body,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (context) {
          body(context);
          return const SizedBox();
        },
      ),
    ),
  );
}
