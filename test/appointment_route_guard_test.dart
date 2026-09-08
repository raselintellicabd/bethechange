import 'package:bethechange/core/network/api_client.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('appointment route without sourceContext redirects away',
      (tester) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(createMockApiClient()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.appointment);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
    expect(find.text('Request Appointment'), findsNothing);
  });

  testWidgets('appointment route with sourceContext shows booking header',
      (tester) async {
    final router = createAppRouter();
    const context = SourceContext(
      type: SourceContextType.service,
      id: 'frequency-specific-microcurrent',
      name: 'Frequency Specific Microcurrent Therapy',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(
            createMockApiClient(now: DateTime(2026, 9, 8, 10)),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    router.go(AppRoutes.appointmentPath(context));
    // Avoid pumpAndSettle: table_calendar keeps animating.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Reason: Frequency Specific Microcurrent Therapy'),
      findsOneWidget,
    );
    expect(find.text('Select a date'), findsOneWidget);
  });
}
