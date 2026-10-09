import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../data/live_chat_repository.dart';
import '../../data/live_chat_token_store.dart';
import '../../domain/models/live_chat.dart';

final liveChatTokenStoreProvider = Provider<LiveChatTokenStore>((ref) {
  return LiveChatTokenStore();
});

final liveChatRepositoryProvider = Provider<LiveChatRepository>((ref) {
  return LiveChatRepository(
    ref.watch(apiClientProvider),
    ref.watch(liveChatTokenStoreProvider),
  );
});

class LiveChatUiState {
  const LiveChatUiState({
    this.restored = false,
    this.status = LiveChatStatus.none,
    this.staffName = '',
    this.fallback = false,
    this.messages = const [],
    this.isStarting = false,
    this.isEnding = false,
    this.pendingText,
    this.startError,
    this.errorMessage,
  });

  /// The saved chat (if any) has been loaded from the server.
  final bool restored;
  final LiveChatStatus status;
  final String staffName;
  final bool fallback;
  final List<LiveChatMessage> messages;
  final bool isStarting;
  final bool isEnding;

  /// Visitor message currently being sent.
  final String? pendingText;
  final String? startError;
  final String? errorMessage;

  bool get isSending => pendingText != null;

  LiveChatUiState copyWith({
    bool? restored,
    LiveChatStatus? status,
    String? staffName,
    bool? fallback,
    List<LiveChatMessage>? messages,
    bool? isStarting,
    bool? isEnding,
    String? pendingText,
    String? startError,
    String? errorMessage,
    bool clearPending = false,
    bool clearStartError = false,
    bool clearError = false,
  }) {
    return LiveChatUiState(
      restored: restored ?? this.restored,
      status: status ?? this.status,
      staffName: staffName ?? this.staffName,
      fallback: fallback ?? this.fallback,
      messages: messages ?? this.messages,
      isStarting: isStarting ?? this.isStarting,
      isEnding: isEnding ?? this.isEnding,
      pendingText: clearPending ? null : (pendingText ?? this.pendingText),
      startError: clearStartError ? null : (startError ?? this.startError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Mirrors the website widget: poll `state` while the chat screen is visible,
/// fetch only messages newer than the last one seen, stop once the chat ends.
///
/// Polling is also the visitor heartbeat: the server ends the chat
/// ("Visitor left the chat.") after a couple of minutes without one.
class LiveChatController extends StateNotifier<LiveChatUiState> {
  LiveChatController(
    this._repository, {
    this.pollInterval = const Duration(milliseconds: 2500),
  }) : super(const LiveChatUiState());

  final LiveChatRepository _repository;
  final Duration pollInterval;

  Timer? _timer;
  bool _visible = false;
  bool _polling = false;
  bool _restoring = false;

  int get _lastId => state.messages.isEmpty ? 0 : state.messages.last.id;

  /// Chat screen shown (or app resumed while it is shown).
  Future<void> open() async {
    _visible = true;
    if (!state.restored) {
      await _restore();
    } else {
      await _poll();
    }
  }

  /// Chat screen hidden or app sent to background.
  void close() {
    _visible = false;
    _timer?.cancel();
  }

  Future<void> _restore() async {
    if (_restoring) return;
    _restoring = true;
    if (await _repository.hasToken()) {
      final result = await _repository.state();
      if (!mounted) return;
      if (result case ApiSuccess(:final data)) {
        await _apply(data);
      }
    }
    _restoring = false;
    if (!mounted) return;
    state = state.copyWith(restored: true);
    _schedule();
  }

  Future<bool> start({
    required String name,
    required String email,
    String message = '',
  }) async {
    if (state.isStarting) return false;
    state = state.copyWith(isStarting: true, clearStartError: true);
    final result = await _repository.start(
      name: name.trim(),
      email: email.trim(),
      message: message.trim(),
    );
    if (!mounted) return false;
    switch (result) {
      case ApiSuccess(:final data):
        state = state.copyWith(isStarting: false, messages: const []);
        await _apply(data);
        _schedule();
        return true;
      case ApiFailure(:final message):
        state = state.copyWith(isStarting: false, startError: message);
        return false;
    }
  }

  Future<bool> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending || !state.status.isOpen) return false;
    state = state.copyWith(pendingText: text, clearError: true);
    final result = await _repository.send(text, since: _lastId);
    if (!mounted) return false;
    switch (result) {
      case ApiSuccess(:final data):
        state = state.copyWith(clearPending: true);
        await _apply(data);
        return true;
      case ApiFailure(:final message):
        state = state.copyWith(clearPending: true, errorMessage: message);
        // The chat may have ended meanwhile; refresh to show it.
        unawaited(_poll());
        return false;
    }
  }

  Future<void> end() async {
    if (state.isEnding || !state.status.isOpen) return;
    state = state.copyWith(isEnding: true, clearError: true);
    final result = await _repository.end(since: _lastId);
    if (!mounted) return;
    state = state.copyWith(isEnding: false);
    result.when(
      success: _apply,
      failure: (message, _) => state = state.copyWith(errorMessage: message),
    );
  }

  /// Forget the (ended) chat so a new one can be started.
  Future<void> reset() async {
    _timer?.cancel();
    await _repository.forget();
    if (!mounted) return;
    state = const LiveChatUiState(restored: true);
  }

  Future<void> _poll() async {
    if (_polling || !_visible || !state.status.isOpen) return;
    _polling = true;
    _timer?.cancel();
    final result = await _repository.state(since: _lastId);
    _polling = false;
    if (!mounted) return;
    if (result case ApiSuccess(:final data)) {
      await _apply(data);
    }
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!mounted || !_visible || !state.status.isOpen) return;
    _timer = Timer(pollInterval, _poll);
  }

  Future<void> _apply(LiveChatSnapshot snapshot) async {
    if (snapshot.status == LiveChatStatus.none) {
      // Token unknown to the server: start over.
      await _repository.forget();
      if (!mounted) return;
      state = const LiveChatUiState(restored: true);
      return;
    }
    final byId = {for (final m in state.messages) m.id: m};
    for (final m in snapshot.messages) {
      byId[m.id] = m;
    }
    final merged = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    state = state.copyWith(
      status: snapshot.status,
      staffName: snapshot.staffName,
      fallback: snapshot.fallback,
      messages: merged,
    );
    if (!snapshot.status.isOpen) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final liveChatControllerProvider =
    StateNotifierProvider<LiveChatController, LiveChatUiState>((ref) {
  return LiveChatController(ref.watch(liveChatRepositoryProvider));
});
