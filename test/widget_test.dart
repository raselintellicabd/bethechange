import 'package:bethechange/app.dart';
import 'package:bethechange/core/config/app_flavor.dart';
import 'package:bethechange/core/config/env_config.dart';
import 'package:bethechange/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EnvConfig.load(AppFlavor.dev);
  });

  testWidgets('Home loads hero, conditions, therapies, doctors, reviews',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(createMockApiClient()),
        ],
        child: const BeTheChangeApp(flavor: AppFlavor.dev),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Be The Change'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
    expect(find.byTooltip('About'), findsOneWidget);

    expect(find.textContaining('root cause'), findsWidgets);

    await tester.scrollUntilVisible(
      find.textContaining('conditions we treat'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Diabetes'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Featured Therapies'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Featured Therapies'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Meet Our Doctors'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Meet Our Doctors'), findsOneWidget);

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
