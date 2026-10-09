import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../live_chat/presentation/providers/live_chat_providers.dart';
import '../../../live_chat/presentation/widgets/chat_app_bar.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chatbot_config.dart';
import '../providers/chatbot_providers.dart';
import '../utils/chatbot_link_route.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumeOpenLiveChat());
  }

  /// Like the website widget: an ongoing live chat takes over the assistant.
  Future<void> _resumeOpenLiveChat() async {
    final live = ref.read(liveChatControllerProvider.notifier);
    await live.open();
    live.close();
    if (!mounted) return;
    if (ref.read(liveChatControllerProvider).status.isOpen) _talkToPerson();
  }

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
    if (mounted) setState(() {});
  }

  void _talkToPerson() {
    context.push(AppRoutes.liveChatFromAssistant);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatbotControllerProvider);
    final configAsync = ref.watch(chatbotConfigProvider);
    final canSend = _controller.text.trim().isNotEmpty && !state.isSending;

    ref.listen<ChatbotUiState>(chatbotControllerProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isSending != next.isSending) {
        _scrollToEnd();
      }
      if (next.handoffRequested && previous?.handoffRequested != true) {
        ref.read(chatbotControllerProvider.notifier).handoffHandled();
        _talkToPerson();
      }
    });

    return Scaffold(
      appBar: chatAppBar(
        title: 'Be The Change',
        subtitle: 'Virtual assistant',
        actions: [
          if (state.messages.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (_) =>
                  ref.read(chatbotControllerProvider.notifier).reset(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'new', child: Text('New conversation')),
              ],
            ),
        ],
      ),
      body: configAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading…'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(chatbotConfigProvider),
        ),
        data: (config) => _ChatbotBody(
          state: state,
          config: config,
          controller: _controller,
          scrollController: _scrollController,
          canSend: canSend,
          onChanged: () => setState(() {}),
          onSubmit: _submit,
          onTalkToPerson: _talkToPerson,
        ),
      ),
    );
  }
}

class _ChatbotBody extends ConsumerWidget {
  const _ChatbotBody({
    required this.state,
    required this.config,
    required this.controller,
    required this.scrollController,
    required this.canSend,
    required this.onChanged,
    required this.onSubmit,
    required this.onTalkToPerson,
  });

  final ChatbotUiState state;
  final ChatbotConfig config;
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool canSend;
  final VoidCallback onChanged;
  final Future<void> Function([String? preset]) onSubmit;
  final VoidCallback onTalkToPerson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (config.welcome.isNotEmpty)
                _ChatBubble(
                  message: ChatMessage(
                    id: 'welcome',
                    role: ChatMessageRole.bot,
                    text: config.welcome,
                    createdAt: DateTime(2000),
                  ),
                ),
              if (state.messages.isEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in config.suggestions)
                      OutlinedButton(
                        onPressed: state.isSending
                            ? null
                            : () => onSubmit(suggestion.message),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.forest),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(suggestion.label),
                      ),
                    FilledButton.icon(
                      onPressed: onTalkToPerson,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('Talk to a person'),
                    ),
                  ],
                ),
              for (final message in state.messages)
                _ChatBubble(message: message),
              if (state.isSending) const _TypingIndicator(),
            ],
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
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (config.disclaimer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      config.disclaimer,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        textInputAction: TextInputAction.send,
                        enabled: !state.isSending,
                        decoration: const InputDecoration(
                          hintText: 'Ask a question…',
                          counterText: '',
                        ),
                        onChanged: (_) => onChanged(),
                        onSubmitted: (_) {
                          if (canSend) onSubmit();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      onPressed: canSend ? () => onSubmit() : null,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.send),
                      tooltip: 'Send',
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onTalkToPerson,
                  child: const Text(
                    'Talk to a person',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends ConsumerWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.role == ChatMessageRole.user;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser ? AppColors.forest : const Color(0xFFE8ECEE);
    final fg = isUser ? Colors.white : AppColors.ink;

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
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: AppTextStyles.bodyMedium.copyWith(color: fg),
            ),
            for (final link in message.links)
              InkWell(
                onTap: () => _openLink(context, ref, link),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    link.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.ochreDark,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static void _openLink(BuildContext context, WidgetRef ref, ChatbotLink link) {
    final target = chatbotLinkTarget(link);
    if (target == null) {
      ref.read(externalLinkHandlerProvider).openExternal(_absoluteUrl(link.url));
    } else if (target.useGo) {
      context.go(target.path);
    } else {
      context.push(target.path);
    }
  }

  /// Assistant links are site-relative (e.g. `/services/ozone-therapy/`).
  static String _absoluteUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    try {
      return Uri.parse(EnvConfig.apiBaseUrl).resolve(url).toString();
    } catch (_) {
      return url;
    }
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE8ECEE),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Text(
          '•••',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkMuted),
        ),
      ),
    );
  }
}
