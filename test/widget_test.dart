import 'package:bethechange/app.dart';
import 'package:bethechange/core/config/app_flavor.dart';
import 'package:bethechange/core/config/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EnvConfig.load(AppFlavor.dev);
  });

  testWidgets('Home loads About, doctors, and horizontal reviews',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BeTheChangeApp(flavor: AppFlavor.dev),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Be The Change'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.byTooltip('About'), findsNothing);
    expect(find.text('Conditions we treat'), findsNothing);
    expect(find.text('Featured therapies'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('About Our Practice'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('About Our Practice'), findsOneWidget);

    await tester.tap(find.text('Naturopathic'));
    await tester.pumpAndSettle();
    expect(find.text('What is Naturopathic Medicine?'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Meet our doctors'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Meet our doctors'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('What our patients say'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('What our patients say'), findsOneWidget);
    expect(find.text('Elle'), findsOneWidget);

    await tester.drag(find.text('Elle'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Manzur Ahmed'), findsOneWidget);
  });
}
