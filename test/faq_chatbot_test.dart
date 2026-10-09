import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/features/chatbot/domain/models/chat_message.dart';
import 'package:bethechange/features/chatbot/domain/models/chatbot_config.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/chatbot/presentation/providers/chatbot_providers.dart';
import 'package:bethechange/features/chatbot/presentation/utils/chatbot_link_route.dart';
import 'package:bethechange/features/faq/data/faq_repository.dart';
import 'package:bethechange/features/faq/domain/models/faq_catalog.dart';
import 'package:bethechange/features/faq/domain/models/faq_item.dart';
import 'package:bethechange/features/faq/presentation/providers/faq_providers.dart';
import 'package:bethechange/features/live_chat/data/live_chat_token_store.dart';
import 'package:bethechange/features/live_chat/presentation/providers/live_chat_providers.dart';
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
      expect(catalog.title, 'FAQ');
      expect(catalog.items.length, greaterThanOrEqualTo(9));
      expect(catalog.sections.map((section) => section.id), [
        'appointments',
        'therapies',
      ]);
      expect(
        catalog.sections.first.title,
        'Common Questions About Our Appointments',
      );
      expect(catalog.policies?.title, 'Office Policies');
      expect(catalog.policies?.content, contains('\$100 deposit'));
      expect(
        catalog.buttonLabel,
        'Click Here to Get started on Your healing journey',
      );
      expect(catalog.buttonUrl, contains('/contact/'));
      expect(catalog.reviews, isNotEmpty);
      expect(catalog.reviews.first.reviewerName, 'Elle');
      expect(catalog.reviews.first.imageUrl, isNotNull);
      expect(catalog.displaySections, isNotEmpty);
      expect(
        catalog.displaySections
            .expand((section) => section.items)
            .any((item) => item.id == catalog.policies!.id),
        isFalse,
      );
      for (final item in catalog.items) {
        expect(item.question, isNotEmpty);
        expect(item.answer, isNotEmpty);
      }
    });
  });

  group('ChatbotApiRepository', () {
    test('returns a reply for common prompts', () async {
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

      for (final prompt in prompts) {
        final result = await repo.ask(message: prompt);
        expect(result, isA<ApiSuccess>());
        final reply = (result as ApiSuccess).data;
        expect(reply.reply, isNotEmpty);
        expect(reply.handoff, isFalse);
      }
    });

    test('asking for a person requests handoff', () async {
      final result = await createMockChatbotRepository()
          .ask(message: 'Can I talk to a person?');
      final reply = (result as ApiSuccess).data;
      expect(reply.handoff, isTrue);
    });

    test('force error simulates failure', () async {
      final result = await createMockChatbotRepository()
          .ask(message: 'please force error now');

      expect(result, isA<ApiFailure>());
    });

    test('bundled config matches the website widget', () async {
      final result = await createMockChatbotRepository().getConfig();
      final config = (result as ApiSuccess<ChatbotConfig>).data;
      expect(config.welcome, contains('virtual assistant'));
      expect(config.suggestions.map((s) => s.label), [
        'Our services',
        'Conditions we treat',
        'Insurance',
      ]);
      expect(config.suggestions.first.message, 'What services do you offer?');
    });
  });

  group('chatbotLinkTarget', () {
    ChatbotLinkTarget? target(String kind, String url, [String title = 'X']) =>
        chatbotLinkTarget(ChatbotLink(title: title, url: url, kind: kind));

    test('content pages open their detail screens', () {
      expect(
        target('Service', '/hyperbaric-oxygen-therapy/'),
        ChatbotLinkTarget(
          AppRoutes.serviceDetailPath('hyperbaric-oxygen-therapy'),
        ),
      );
      expect(
        target('Condition', '/diabetes/'),
        ChatbotLinkTarget(AppRoutes.conditionDetailPath('diabetes')),
      );
      expect(
        target('Blog', '/healthy-fall/'),
        ChatbotLinkTarget(AppRoutes.blogDetailPath('healthy-fall')),
      );
    });

    test('about pages and doctors open under About', () {
      expect(
        target('About', '/about/'),
        const ChatbotLinkTarget(AppRoutes.about, useGo: true),
      );
      expect(
        target('About', '/about/naturopathic-medicine/'),
        ChatbotLinkTarget(
          AppRoutes.aboutSectionPath('naturopathic-medicine'),
          useGo: true,
        ),
      );
      expect(
        target('About', '/our-process/'),
        ChatbotLinkTarget(
          AppRoutes.aboutSectionPath('our-process'),
          useGo: true,
        ),
      );
      expect(
        target('Doctor', '/about/dr-afrooz/'),
        ChatbotLinkTarget(AppRoutes.aboutSectionPath('dr-afrooz'), useGo: true),
      );
    });

    test('booking links open the in-app booking flow', () {
      final category = target(
        'Booking',
        '/book-online/?category=hyperbaric-oxygen-therapy',
        'Book Hyperbaric Oxygen Therapy online',
      );
      expect(
        category,
        ChatbotLinkTarget(
          AppRoutes.bookOnlinePath(
            const SourceContext(
              type: SourceContextType.service,
              id: 'hyperbaric-oxygen-therapy',
              name: 'Hyperbaric Oxygen Therapy',
            ),
          ),
        ),
      );
      expect(
        target('Booking', '/book-online/'),
        const ChatbotLinkTarget(AppRoutes.exploreServices, useGo: true),
      );
      expect(
        target('Booking', '/appointments/'),
        ChatbotLinkTarget(
          AppRoutes.appointmentPath(AppRoutes.clinicSourceContext),
        ),
      );
    });

    test('section pages', () {
      expect(target('FAQ', '/faq/'), const ChatbotLinkTarget(AppRoutes.faq));
      expect(
        target('Memberships', '/memberships/'),
        const ChatbotLinkTarget(AppRoutes.membership),
      );
      expect(
        target('Package', '/packages/'),
        const ChatbotLinkTarget(AppRoutes.packages),
      );
      expect(
        target('Contact', '/contact/'),
        const ChatbotLinkTarget(AppRoutes.contact),
      );
      expect(
        target('Patients', '/patients/'),
        const ChatbotLinkTarget(AppRoutes.patients, useGo: true),
      );
    });

    test('unknown or external links fall back to the browser', () {
      expect(target('', '/something/'), isNull);
      expect(target('Shop', '/shop/'), isNull);
      expect(target('Service', '/a/b/'), isNull);
      expect(target('Booking', '/checkout/'), isNull);
      expect(target('Service', 'https://example.com/ozone/'), isNull);
    });

    test('kind is parsed from the API', () {
      final reply = ChatbotReply.fromJson({
        'reply': 'ok',
        'links': [
          {'title': 'Ozone', 'url': '/ozone-therapy/', 'kind': 'Service'},
        ],
      });
      expect(reply.links.single.kind, 'Service');
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
      expect(state.handoffRequested, isFalse);

      await controller.send('I want to talk to a person');
      state = container.read(chatbotControllerProvider);
      expect(state.handoffRequested, isTrue);
      controller.handoffHandled();
      expect(container.read(chatbotControllerProvider).handoffRequested,
          isFalse);
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
        ChatbotSuggestion(
          label: 'Our services',
          message: 'What services do you offer?',
        ),
        ChatbotSuggestion(
          label: 'Insurance',
          message: 'Do you accept insurance?',
        ),
      ],
      disclaimer: 'Automated assistant. Not medical advice.',
      welcome: "Hi! I'm the Be The Change virtual assistant.",
    );

    testWidgets('FAQ expands answers', (tester) async {
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
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('How do I schedule?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('new patient form'), findsOneWidget);
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
            liveChatTokenStoreProvider.overrideWithValue(
              MemoryLiveChatTokenStore(),
            ),
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
