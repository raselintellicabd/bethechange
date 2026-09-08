import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chatbot_repository.dart';
import '../../data/mock_chatbot_repository.dart';
import '../../domain/models/chat_message.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return MockChatbotRepository();
});

class ChatbotUiState {
  const ChatbotUiState({
    this.messages = const [],
    this.conversationId,
    this.isSending = false,
    this.errorMessage,
    this.pendingRetryText,
  });

  final List<ChatMessage> messages;
  final String? conversationId;
  final bool isSending;
  final String? errorMessage;

  /// Last user text that failed to send (for retry).
  final String? pendingRetryText;

  bool get canRetry =>
      pendingRetryText != null && pendingRetryText!.trim().isNotEmpty;

  ChatbotUiState copyWith({
    List<ChatMessage>? messages,
    String? conversationId,
    bool? isSending,
    String? errorMessage,
    String? pendingRetryText,
    bool clearError = false,
    bool clearPendingRetry = false,
  }) {
    return ChatbotUiState(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingRetryText: clearPendingRetry
          ? null
          : (pendingRetryText ?? this.pendingRetryText),
    );
  }
}

class ChatbotController extends StateNotifier<ChatbotUiState> {
  ChatbotController(this._repository) : super(const ChatbotUiState());

  final ChatbotRepository _repository;
  int _idCounter = 0;

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;

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

    final result = await _repository.sendMessage(
      message: text,
      conversationId: state.conversationId,
    );

    result.when(
      success: (reply) {
        final botMessage = ChatMessage(
          id: 'local-${++_idCounter}',
          role: ChatMessageRole.bot,
          text: reply.reply,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, botMessage],
          conversationId: reply.conversationId,
          isSending: false,
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
}

final chatbotControllerProvider =
    StateNotifierProvider<ChatbotController, ChatbotUiState>((ref) {
  return ChatbotController(ref.watch(chatbotRepositoryProvider));
});
