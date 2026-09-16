import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/widgets/appointment_cta_bar.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppointmentCtaBar', () {
    test('condition CTA encodes appointment route', () {
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

    test('mapped service CTA encodes book-online route', () {
      const context = SourceContext(
        type: SourceContextType.service,
        id: 'ion-foot-detox',
        name: 'Ion Foot Detox',
      );

      final location = AppointmentCtaBar.locationFor(context);
      final uri = Uri.parse(location);

      expect(uri.path, AppRoutes.bookOnline);
      expect(
        SourceContext.tryParse(uri.queryParameters['sourceContext']),
        context,
      );
    });

    test('unmapped service CTA still opens appointment', () {
      const context = SourceContext(
        type: SourceContextType.service,
        id: 'wellness-classes',
        name: 'Wellness Classes',
      );

      final location = AppointmentCtaBar.locationFor(context);
      expect(Uri.parse(location).path, AppRoutes.appointment);
    });

    testWidgets('tapping CTA navigates to book-online for mapped service',
        (tester) async {
      const sourceContext = SourceContext(
        type: SourceContextType.service,
        id: 'frequency-specific-microcurrent',
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
            path: AppRoutes.bookOnline,
            builder: (context, state) {
              final raw = state.uri.queryParameters['sourceContext'];
              final parsed = SourceContext.tryParse(raw);
              return Scaffold(
                body: Text(
                  parsed == null
                      ? 'missing'
                      : 'book-online:${parsed.type.name}:${parsed.id}',
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.appointment,
            builder: (context, state) => const Scaffold(
              body: Text('appointment'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Request an appointment'), findsOneWidget);

      await tester.tap(find.text('Request an appointment'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'book-online:service:frequency-specific-microcurrent',
        ),
        findsOneWidget,
      );
      expect(find.text('appointment'), findsNothing);
    });

    testWidgets('condition CTA still navigates to appointment', (tester) async {
      const sourceContext = SourceContext(
        type: SourceContextType.condition,
        id: 'diabetes',
        name: 'Diabetes',
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

      await tester.tap(find.text('Request an appointment'));
      await tester.pumpAndSettle();

      expect(find.text('condition:diabetes:Diabetes'), findsOneWidget);
    });
  });
}
