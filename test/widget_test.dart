import 'package:bethechange/app.dart';
import 'package:bethechange/core/config/app_flavor.dart';
import 'package:bethechange/core/config/env_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EnvConfig.load(AppFlavor.dev);
  });

  testWidgets('About tab loads subtabs from content', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BeTheChangeApp(flavor: AppFlavor.dev),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About'), findsWidgets);
    expect(find.text('Our Practice'), findsWidgets);
    expect(find.text('Naturopathic Medicine'), findsOneWidget);
    expect(find.text('Integrative Medicine'), findsOneWidget);
    expect(find.text('Our Process'), findsOneWidget);
    expect(find.text('About Our Practice'), findsOneWidget);

    await tester.tap(find.text('Naturopathic Medicine'));
    await tester.pumpAndSettle();
    expect(find.text('What is Naturopathic Medicine?'), findsOneWidget);

    await tester.tap(find.text('Integrative Medicine'));
    await tester.pumpAndSettle();
    expect(find.text('What is Integrative Medicine?'), findsOneWidget);

    await tester.tap(find.text('Our Process'));
    await tester.pumpAndSettle();
    expect(find.text('Listen, Learn & Apply'), findsOneWidget);
  });
}
