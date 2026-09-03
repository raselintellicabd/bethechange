import 'package:bethechange/app.dart';
import 'package:bethechange/core/config/app_flavor.dart';
import 'package:bethechange/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EnvConfig.load(AppFlavor.dev);
  });

  testWidgets('App launches with About tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BeTheChangeApp(flavor: AppFlavor.dev),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About'), findsWidgets);
    expect(find.text('TODO'), findsOneWidget);
  });
}
