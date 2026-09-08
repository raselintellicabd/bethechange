import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/blog/domain/models/blog_article.dart';
import 'package:bethechange/features/blog/domain/models/blog_catalog.dart';
import 'package:bethechange/features/blog/presentation/providers/blog_providers.dart';
import 'package:bethechange/features/conditions/domain/models/condition.dart';
import 'package:bethechange/features/conditions/domain/models/conditions_catalog.dart';
import 'package:bethechange/features/conditions/presentation/providers/conditions_providers.dart';
import 'package:bethechange/features/services/domain/models/service.dart';
import 'package:bethechange/features/services/domain/models/services_catalog.dart';
import 'package:bethechange/features/services/presentation/providers/services_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleConditions = ConditionsCatalog(
    conditions: [
      Condition(
        id: 'diabetes',
        name: 'Diabetes',
        summary: 'Blood sugar support summary.',
        articleBody: 'Diabetes article body for deep link tests.',
      ),
    ],
  );

  const sampleServices = ServicesCatalog(
    services: [
      Service(
        id: 'fsm',
        name: 'Frequency Specific Microcurrent Therapy',
        summary: 'FSM summary.',
        articleBody: 'FSM article body for deep link tests.',
      ),
    ],
  );

  const sampleBlog = BlogCatalog(
    articles: [
      BlogArticle(
        id: 'what-is-hyperbaric-oxygen-therapy',
        title: 'What is Hyperbaric Oxygen Therapy?',
        subtitle: 'HBOT overview',
        body: 'Hyperbaric oxygen therapy article body.',
      ),
    ],
  );

  List<Override> overrides() => [
        conditionsCatalogProvider.overrideWith((ref) async => sampleConditions),
        servicesCatalogProvider.overrideWith((ref) async => sampleServices),
        blogCatalogProvider.overrideWith((ref) async => sampleBlog),
      ];

  Future<GoRouter> mount(WidgetTester tester) async {
    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    return router;
  }

  String pathOf(GoRouter router) =>
      router.routeInformationProvider.value.uri.path;

  testWidgets('deep link /conditions/:id opens condition detail',
      (tester) async {
    final router = await mount(tester);
    router.go(AppRoutes.conditionDetailPath('diabetes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(pathOf(router), '/conditions/diabetes');
    expect(find.text('Diabetes'), findsWidgets);
    expect(find.textContaining('Diabetes article body'), findsOneWidget);
  });

  testWidgets('deep link /services/:id opens service detail', (tester) async {
    final router = await mount(tester);
    router.go(AppRoutes.serviceDetailPath('fsm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(pathOf(router), '/services/fsm');
    expect(
      find.text('Frequency Specific Microcurrent Therapy'),
      findsWidgets,
    );
    expect(find.textContaining('FSM article body'), findsOneWidget);
  });

  testWidgets('deep link /blog/:id opens blog detail', (tester) async {
    final router = await mount(tester);
    router.go(
      AppRoutes.blogDetailPath('what-is-hyperbaric-oxygen-therapy'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(pathOf(router), '/blog/what-is-hyperbaric-oxygen-therapy');
    expect(find.text('What is Hyperbaric Oxygen Therapy?'), findsWidgets);
    expect(
      find.textContaining('Hyperbaric oxygen therapy article body'),
      findsOneWidget,
    );
  });

  testWidgets('deep link bare /appointment is denied', (tester) async {
    final router = await mount(tester);
    router.go(AppRoutes.appointment);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(pathOf(router), AppRoutes.about);
    expect(find.text('Request Appointment'), findsNothing);
  });

  testWidgets('deep link /appointment with sourceContext is allowed',
      (tester) async {
    final router = await mount(tester);
    const context = SourceContext(
      type: SourceContextType.condition,
      id: 'diabetes',
      name: 'Diabetes',
    );
    router.go(AppRoutes.appointmentPath(context));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(pathOf(router), AppRoutes.appointment);
    expect(
      find.text('Requesting appointment for: Diabetes'),
      findsOneWidget,
    );
  });
}
