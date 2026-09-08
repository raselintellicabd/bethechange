import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/features/blog/domain/models/blog_article.dart';
import 'package:bethechange/features/blog/domain/models/blog_catalog.dart';
import 'package:bethechange/features/blog/presentation/providers/blog_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleCatalog = BlogCatalog(
    articles: [
      BlogArticle(
        id: 'sample-fsm',
        title: 'What Is Frequency-specific Microcurrent Therapy?',
        subtitle: 'A short preview of FSM.',
        body:
            'Frequency specific microcurrent therapy is a modern treatment.\n\nSecond paragraph.',
      ),
      BlogArticle(
        id: 'sample-hbot',
        title: 'What is Hyperbaric Oxygen Therapy?',
        subtitle: 'A short preview of HBOT.',
        body: 'Hyperbaric oxygen therapy overview.',
      ),
    ],
  );

  testWidgets('blog tab lists articles and opens detail', (tester) async {
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blogCatalogProvider.overrideWith((ref) async => sampleCatalog),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    router.go(AppRoutes.blog);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('What Is Frequency-specific Microcurrent Therapy?'),
      findsOneWidget,
    );

    await tester.tap(
      find.text('What Is Frequency-specific Microcurrent Therapy?'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.textContaining(
        'Frequency specific microcurrent therapy is a modern',
      ),
      findsOneWidget,
    );
    expect(find.text('Second paragraph.'), findsOneWidget);
  });

  testWidgets('blog list refresh reloads catalog', (tester) async {
    var loads = 0;
    final router = createAppRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blogCatalogProvider.overrideWith((ref) async {
            loads += 1;
            return sampleCatalog;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    router.go(AppRoutes.blog);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(loads, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(loads, greaterThan(1));
  });
}
