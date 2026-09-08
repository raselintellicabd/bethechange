import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/chat_message.dart';
import '../providers/chatbot_providers.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'How do I book an appointment?',
    'Do you take insurance?',
    'Where are you located?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit([String? preset]) async {
    final text = preset ?? _controller.text;
    if (preset == null) _controller.clear();
    await ref.read(chatbotControllerProvider.notifier).send(text);
    await _scrollToEnd();
    setState(() {});
  }

  Future<void> _scrollToEnd() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatbotControllerProvider);
    final canSend = _controller.text.trim().isNotEmpty && !state.isSending;

    ref.listen<ChatbotUiState>(chatbotControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isSending != next.isSending) {
        _scrollToEnd();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              'This assistant shares general clinic information and is not a '
              'substitute for medical advice.',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
          ),
          Expanded(
            child: state.messages.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Text(
                        'Ask about scheduling, insurance, location, and therapies.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final suggestion in _suggestions)
                            ActionChip(
                              label: Text(suggestion),
                              onPressed: state.isSending
                                  ? null
                                  : () => _submit(suggestion),
                            ),
                        ],
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount:
                        state.messages.length + (state.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (state.isSending &&
                          index == state.messages.length) {
                        return const _TypingIndicator();
                      }
                      return _ChatBubble(message: state.messages[index]);
                    },
                  ),
          ),
          if (state.errorMessage != null)
            Material(
              color: AppColors.sageLight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    if (state.canRetry)
                      AppButton(
                        label: 'Retry',
                        variant: AppButtonVariant.text,
                        expand: false,
                        onPressed: state.isSending
                            ? null
                            : () => ref
                                .read(chatbotControllerProvider.notifier)
                                .retry(),
                      ),
                  ],
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      enabled: !state.isSending,
                      decoration: const InputDecoration(
                        hintText: 'Type your question…',
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (canSend) _submit();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: canSend ? () => _submit() : null,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.ochre,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatMessageRole.user;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser ? AppColors.forest : AppColors.card;
    final fg = isUser ? Colors.white : AppColors.ink;
    final border = isUser ? null : Border.all(color: AppColors.line);

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.bodyMedium.copyWith(color: fg),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.sageLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
