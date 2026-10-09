import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/api_client.dart';
import '../../data/chatbot_api_repository.dart';
import '../../data/chatbot_repository.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chatbot_config.dart';

/// Same window the website widget sends as `history`.
const _historyEntries = 6;

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotApiRepository(ref.watch(apiClientProvider));
});

final chatbotConfigProvider = FutureProvider<ChatbotConfig>((ref) async {
  final result = await ref.watch(chatbotRepositoryProvider).getConfig();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});

class ChatbotUiState {
  const ChatbotUiState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
    this.pendingRetryText,
    this.handoffRequested = false,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;

  /// Last user text that failed to send (for retry).
  final String? pendingRetryText;

  /// The assistant asked to hand the visitor over to live chat.
  final bool handoffRequested;

  bool get canRetry =>
      pendingRetryText != null && pendingRetryText!.trim().isNotEmpty;

  ChatbotUiState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
    String? pendingRetryText,
    bool? handoffRequested,
    bool clearError = false,
    bool clearPendingRetry = false,
  }) {
    return ChatbotUiState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingRetryText: clearPendingRetry
          ? null
          : (pendingRetryText ?? this.pendingRetryText),
      handoffRequested: handoffRequested ?? this.handoffRequested,
    );
  }
}

class ChatbotController extends StateNotifier<ChatbotUiState> {
  ChatbotController(this._repository, this._analytics)
      : super(const ChatbotUiState());

  final ChatbotRepository _repository;
  final AnalyticsService _analytics;
  int _idCounter = 0;

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;

    final history = [
      for (final m in state.messages)
        {
          'role': m.role == ChatMessageRole.user ? 'user' : 'assistant',
          'content': m.text,
        },
    ];
    final recent = history.length > _historyEntries
        ? history.sublist(history.length - _historyEntries)
        : history;

    final userMessage = ChatMessage(
      id: 'local-${++_idCounter}',
      role: ChatMessageRole.user,
      text: text,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
      clearPendingRetry: true,
    );

    final result = await _repository.ask(message: text, history: recent);

    result.when(
      success: (reply) {
        _analytics.logEvent(AnalyticsEvents.chatbotMessageSent);
        final botMessage = ChatMessage(
          id: 'local-${++_idCounter}',
          role: ChatMessageRole.bot,
          text: reply.reply,
          createdAt: DateTime.now(),
          links: reply.links,
        );
        state = state.copyWith(
          messages: [...state.messages, botMessage],
          isSending: false,
          handoffRequested: reply.handoff,
          clearError: true,
          clearPendingRetry: true,
        );
      },
      failure: (message, _) {
        state = state.copyWith(
          isSending: false,
          errorMessage: message,
          pendingRetryText: text,
        );
      },
    );
  }

  Future<void> retry() async {
    final pending = state.pendingRetryText;
    if (pending == null || pending.trim().isEmpty) return;
    // Remove the failed user bubble before re-sending so we do not duplicate.
    final withoutLastUser = [...state.messages];
    if (withoutLastUser.isNotEmpty &&
        withoutLastUser.last.role == ChatMessageRole.user &&
        withoutLastUser.last.text == pending) {
      withoutLastUser.removeLast();
    }
    state = state.copyWith(
      messages: withoutLastUser,
      clearError: true,
      clearPendingRetry: true,
    );
    await send(pending);
  }

  void handoffHandled() {
    if (state.handoffRequested) {
      state = state.copyWith(handoffRequested: false);
    }
  }

  /// Starts a fresh assistant conversation.
  void reset() {
    state = const ChatbotUiState();
  }
}

final chatbotControllerProvider =
    StateNotifierProvider<ChatbotController, ChatbotUiState>((ref) {
  return ChatbotController(
    ref.watch(chatbotRepositoryProvider),
    ref.watch(analyticsServiceProvider),
  );
});
