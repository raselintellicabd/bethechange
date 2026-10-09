import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/features/live_chat/data/live_chat_repository.dart';
import 'package:bethechange/features/live_chat/data/live_chat_token_store.dart';
import 'package:bethechange/features/live_chat/domain/models/live_chat.dart';
import 'package:bethechange/features/live_chat/presentation/providers/live_chat_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LiveChatRepository createRepo(LiveChatTokenStore store) =>
      LiveChatRepository(createMockApiClient(), store);

  group('LiveChatSnapshot', () {
    test('parses the Django session payload', () {
      final s = LiveChatSnapshot.fromJson({
        'id': 7,
        'status': 'active',
        'visitor_name': 'Ann',
        'staff_name': 'Dr. Lee',
        'fallback': false,
        'token': 'abc',
        'messages': [
          {
            'id': 3,
            'sender': 'staff',
            'author': 'Dr. Lee',
            'body': 'Hi',
            'time': '3:18 PM',
          },
          {'id': 4, 'sender': 'system', 'author': '', 'body': 'x', 'time': ''},
        ],
      });
      expect(s.status, LiveChatStatus.active);
      expect(s.token, 'abc');
      expect(s.staffName, 'Dr. Lee');
      expect(s.messages.first.sender, LiveChatSender.staff);
      expect(s.messages.last.sender, LiveChatSender.system);
    });

    test('unknown status means no chat', () {
      expect(
        LiveChatSnapshot.fromJson({'status': 'none', 'messages': []}).status,
        LiveChatStatus.none,
      );
    });
  });

  group('LiveChatRepository', () {
    test('start saves the token and later calls use it', () async {
      final store = MemoryLiveChatTokenStore();
      final repo = createRepo(store);

      final none = await repo.state();
      expect((none as ApiSuccess).data.status, LiveChatStatus.none);

      final started = await repo.start(
        name: 'Ann',
        email: 'ann@example.com',
        message: 'Hello',
      );
      final snapshot = (started as ApiSuccess<LiveChatSnapshot>).data;
      expect(snapshot.status, LiveChatStatus.waiting);
      expect(await store.read(), snapshot.token);

      final sent = await repo.send('Online, please', since: 1);
      final messages = (sent as ApiSuccess<LiveChatSnapshot>).data.messages;
      expect(messages.map((m) => m.body), ['Online, please']);
    });

    test('start validates like the server', () async {
      final result = await createRepo(MemoryLiveChatTokenStore())
          .start(name: 'Ann', email: 'nope');
      expect(result, isA<ApiFailure>());
      expect(
        (result as ApiFailure).message,
        'Please enter a valid email address so we can reply.',
      );
    });
  });

  group('LiveChatController', () {
    test('start, poll until a team member joins, send and end', () async {
      final store = MemoryLiveChatTokenStore();
      final controller = LiveChatController(
        createRepo(store),
        pollInterval: const Duration(milliseconds: 1),
      );
      addTearDown(controller.dispose);

      await controller.open();
      expect(controller.state.restored, isTrue);
      expect(controller.state.status, LiveChatStatus.none);

      final ok = await controller.start(
        name: 'Ann',
        email: 'ann@example.com',
        message: 'Hi, I would like to book.',
      );
      expect(ok, isTrue);
      expect(controller.state.status, LiveChatStatus.waiting);
      expect(controller.state.messages, hasLength(1));

      for (var i = 0; i < 50 &&
              controller.state.status != LiveChatStatus.active;
          i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(controller.state.status, LiveChatStatus.active);
      expect(controller.state.staffName, 'Care team');
      final ids = controller.state.messages.map((m) => m.id).toList();
      expect(ids, ids.toSet().toList(), reason: 'no duplicate messages');

      expect(await controller.send('Online, please.'), isTrue);
      expect(controller.state.messages.last.body, 'Online, please.');
      expect(controller.state.isSending, isFalse);

      await controller.end();
      expect(controller.state.status, LiveChatStatus.ended);
      expect(await controller.send('too late'), isFalse);

      await controller.reset();
      expect(controller.state.status, LiveChatStatus.none);
      expect(await store.read(), isNull);
    });

    test('restores an open chat from the saved token', () async {
      final store = MemoryLiveChatTokenStore();
      final repo = createRepo(store);
      await repo.start(name: 'Ann', email: 'ann@example.com', message: 'Hi');

      final controller = LiveChatController(repo);
      addTearDown(controller.dispose);
      await controller.open();
      controller.close();

      expect(controller.state.status, LiveChatStatus.waiting);
      expect(controller.state.messages.single.body, 'Hi');
    });

    test('forgets a token the server no longer knows', () async {
      final store = MemoryLiveChatTokenStore();
      await store.save('stale-token');
      final controller = LiveChatController(createRepo(store));
      addTearDown(controller.dispose);

      await controller.open();
      controller.close();

      expect(controller.state.status, LiveChatStatus.none);
      expect(await store.read(), isNull);
    });
  });
}
