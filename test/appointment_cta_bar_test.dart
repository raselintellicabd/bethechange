import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/widgets/appointment_cta_bar.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppointmentCtaBar', () {
    test('locationFor encodes a valid SourceContext route', () {
      const context = SourceContext(
        type: SourceContextType.condition,
        id: 'diabetes',
        name: 'Diabetes',
      );

      final location = AppointmentCtaBar.locationFor(context);
      final uri = Uri.parse(location);

      expect(uri.path, AppRoutes.appointment);
      expect(
        SourceContext.tryParse(uri.queryParameters['sourceContext']),
        context,
      );
    });

    testWidgets('tapping CTA navigates to appointment with context',
        (tester) async {
      const sourceContext = SourceContext(
        type: SourceContextType.service,
        id: 'fsm',
        name: 'Frequency Specific Microcurrent Therapy',
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: AppointmentCtaBar(sourceContext: sourceContext),
            ),
          ),
          GoRoute(
            path: AppRoutes.appointment,
            builder: (context, state) {
              final raw = state.uri.queryParameters['sourceContext'];
              final parsed = SourceContext.tryParse(raw);
              return Scaffold(
                body: Text(
                  parsed == null
                      ? 'missing'
                      : '${parsed.type.name}:${parsed.id}:${parsed.name}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Request an appointment'), findsOneWidget);
      expect(
        find.text('Reason: Frequency Specific Microcurrent Therapy'),
        findsOneWidget,
      );

      await tester.tap(find.text('Request an appointment'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'service:fsm:Frequency Specific Microcurrent Therapy',
        ),
        findsOneWidget,
      );
    });
  });
}
