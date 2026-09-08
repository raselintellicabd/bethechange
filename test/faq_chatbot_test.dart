import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/features/chatbot/domain/models/chat_message.dart';
import 'package:bethechange/features/chatbot/domain/models/chatbot_config.dart';
import 'package:bethechange/features/chatbot/presentation/providers/chatbot_providers.dart';
import 'package:bethechange/features/faq/data/faq_repository.dart';
import 'package:bethechange/features/faq/domain/models/faq_catalog.dart';
import 'package:bethechange/features/faq/domain/models/faq_item.dart';
import 'package:bethechange/features/faq/presentation/providers/faq_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FaqCatalog', () {
    test('parses bundled faq.json', () async {
      final result = await FaqRepository(createMockApiClient()).getFaq();
      expect(result, isA<ApiSuccess<FaqCatalog>>());
      final catalog = (result as ApiSuccess<FaqCatalog>).data;
      expect(catalog.items.length, greaterThanOrEqualTo(9));
      for (final item in catalog.items) {
        expect(item.question, isNotEmpty);
        expect(item.answer, isNotEmpty);
      }
    });
  });

  group('ChatbotApiRepository', () {
    test('returns reply and conversationId for common prompts', () async {
      final repo = createMockChatbotRepository();

      const prompts = [
        'hello',
        'How do I schedule an appointment?',
        'Do you take insurance?',
        'Where are you located?',
        'What are your hours?',
        'What therapies do you offer?',
        'How do I open the patient portal?',
        'Where can I shop supplements?',
        'How much does a visit cost?',
        'Tell me about the doctors',
        'Where is the FAQ?',
      ];

      expect(prompts, hasLength(greaterThanOrEqualTo(10)));

      String? conversationId;
      for (final prompt in prompts) {
        final result = await repo.sendMessage(
          message: prompt,
          conversationId: conversationId,
        );
        expect(result, isA<ApiSuccess>());
        final reply = (result as ApiSuccess).data;
        expect(reply.reply, isNotEmpty);
        expect(reply.conversationId, isNotEmpty);
        conversationId = reply.conversationId;
      }
    });

    test('force error simulates failure', () async {
      final result = await createMockChatbotRepository()
          .sendMessage(message: 'please force error now');

      expect(result, isA<ApiFailure>());
    });
  });

  group('ChatbotController', () {
    test('send success and retry after failure', () async {
      final container = ProviderContainer(
        overrides: [
          chatbotRepositoryProvider.overrideWithValue(
            createMockChatbotRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(chatbotControllerProvider.notifier);

      await controller.send('force error');
      var state = container.read(chatbotControllerProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.canRetry, isTrue);
      expect(
        state.messages.where((m) => m.role == ChatMessageRole.bot),
        isEmpty,
      );

      await controller.send('hello there');
      state = container.read(chatbotControllerProvider);
      expect(
        state.messages.where((m) => m.role == ChatMessageRole.bot),
        isNotEmpty,
      );
      expect(state.conversationId, isNotNull);
    });
  });

  group('FAQ / Chatbot UI', () {
    final sampleCatalog = FaqCatalog(
      items: const [
        FaqItem(
          id: 'how-do-i-schedule',
          question: 'How do I schedule?',
          answer: 'Please fill out the new patient form to get started.',
        ),
        FaqItem(
          id: 'insurance',
          question: 'Do we accept insurance?',
          answer: 'We are out-of-network and do not bill insurance directly.',
        ),
      ],
    );

    const sampleConfig = ChatbotConfig(
      suggestions: [
        'How do I book an appointment?',
        'Do you take insurance?',
        'Where are you located?',
      ],
      disclaimer:
          'This assistant shares general clinic information and is not a '
          'substitute for medical advice.',
      emptyPrompt: 'Ask about scheduling, insurance, location, and therapies.',
    );

    testWidgets('FAQ expands and opens chatbot', (tester) async {
      final router = createAppRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            faqCatalogProvider.overrideWith((ref) async => sampleCatalog),
            chatbotRepositoryProvider.overrideWithValue(
              createMockChatbotRepository(),
            ),
            chatbotConfigProvider.overrideWith((ref) async => sampleConfig),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      router.go(AppRoutes.faq);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('FAQ'), findsWidgets);
      expect(find.text('New Patient Questions'), findsNothing);
      expect(find.text('How do I schedule?'), findsOneWidget);

      await tester.tap(find.text('How do I schedule?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('new patient form'), findsOneWidget);

      await tester.ensureVisible(find.byType(FloatingActionButton));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Assistant'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('chatbot send disabled when empty; retry after force error',
        (tester) async {
      final router = createAppRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatbotRepositoryProvider.overrideWithValue(
              createMockChatbotRepository(),
            ),
            chatbotConfigProvider.overrideWith((ref) async => sampleConfig),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      router.go(AppRoutes.chatbot);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final send = find.widgetWithIcon(IconButton, Icons.send);
      expect(tester.widget<IconButton>(send).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'force error');
      await tester.pump();
      expect(tester.widget<IconButton>(send).onPressed, isNotNull);

      await tester.tap(send);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('Unable to reach the chatbot'), findsOneWidget);
    });
  });
}
