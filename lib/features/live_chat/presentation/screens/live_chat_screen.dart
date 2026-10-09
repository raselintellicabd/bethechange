import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/live_chat.dart';
import '../providers/live_chat_providers.dart';
import '../widgets/chat_app_bar.dart';

const _emergencyNote =
    "You're chatting with our team. For emergencies, call your local "
    'emergency number.';

/// Live chat with the clinic team: start form when there is no chat,
/// otherwise the conversation (waiting → active → ended).
class LiveChatScreen extends ConsumerStatefulWidget {
  const LiveChatScreen({super.key, this.fromAssistant = false});

  /// Opened from the assistant, so "Back to assistant" just pops.
  final bool fromAssistant;

  @override
  ConsumerState<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends ConsumerState<LiveChatScreen>
    with WidgetsBindingObserver {
  late final LiveChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(liveChatControllerProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.open());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.open();
    } else {
      _controller.close();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.close();
    super.dispose();
  }

  void _backToAssistant() {
    if (widget.fromAssistant && context.canPop()) {
      context.pop();
    } else {
      context.pushReplacement(AppRoutes.chatbot);
    }
  }

  Future<void> _newChatBackToAssistant() async {
    await _controller.reset();
    if (mounted) _backToAssistant();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveChatControllerProvider);

    if (!state.restored) {
      return Scaffold(
        appBar: chatAppBar(title: 'Be The Change', subtitle: 'Live chat'),
        body: const LoadingIndicator(message: 'Loading…'),
      );
    }

    if (state.status == LiveChatStatus.none) {
      return Scaffold(
        appBar: chatAppBar(
          title: 'Be The Change',
          subtitle: 'Chat with our team',
        ),
        body: _StartChatForm(
          isStarting: state.isStarting,
          error: state.startError,
          onSubmit: (name, email, message) => _controller.start(
            name: name,
            email: email,
            message: message,
          ),
          onBack: _backToAssistant,
        ),
      );
    }

    final ended = state.status == LiveChatStatus.ended;
    final active = state.status == LiveChatStatus.active;
    return Scaffold(
      appBar: chatAppBar(
        title: active && state.staffName.isNotEmpty
            ? state.staffName
            : 'Care team',
        subtitle: switch (state.status) {
          LiveChatStatus.waiting => 'Waiting · Live chat',
          LiveChatStatus.active => 'Live chat',
          _ => 'Chat ended',
        },
        initialsFrom: active ? state.staffName : '',
        actions: [
          if (!ended)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: OutlinedButton(
                onPressed: state.isEnding ? null : () => _confirmEnd(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('End chat'),
              ),
            ),
        ],
      ),
      body: _Conversation(
        state: state,
        onSend: _controller.send,
        onNewChat: _controller.reset,
        onBackToAssistant: _newChatBackToAssistant,
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End chat'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.end();
  }
}

class _StartChatForm extends ConsumerStatefulWidget {
  const _StartChatForm({
    required this.isStarting,
    required this.error,
    required this.onSubmit,
    required this.onBack,
  });

  final bool isStarting;
  final String? error;
  final Future<bool> Function(String name, String email, String message)
      onSubmit;
  final VoidCallback onBack;

  @override
  ConsumerState<_StartChatForm> createState() => _StartChatFormState();
}

class _StartChatFormState extends ConsumerState<_StartChatForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final name = user == null
        ? ''
        : '${user.firstName} ${user.lastName}'.trim();
    _name = TextEditingController(text: name);
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_name.text, _email.text, _message.text);
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.labelLarge.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.forest,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md + 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.line),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chat with our team',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                "Tell us who you are and we'll connect you with someone.",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Your name', style: labelStyle),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _name,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(counterText: ''),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Please enter your name.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Email', style: labelStyle),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _email,
                maxLength: 254,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(counterText: ''),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email address so we can reply.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Message', style: labelStyle),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _message,
                maxLength: 2000,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'How can we help?',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Please don't share personal health details in this chat. "
                'For emergencies, call your local emergency number.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              if (widget.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.error!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: widget.isStarting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
                icon: widget.isStarting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat_bubble_outline),
                label: const Text('Start chat'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: widget.onBack,
                child: const Text(
                  'Back to assistant',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Conversation extends StatefulWidget {
  const _Conversation({
    required this.state,
    required this.onSend,
    required this.onNewChat,
    required this.onBackToAssistant,
  });

  final LiveChatUiState state;
  final Future<bool> Function(String text) onSend;
  final Future<void> Function() onNewChat;
  final Future<void> Function() onBackToAssistant;

  @override
  State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void didUpdateWidget(covariant _Conversation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.messages.length != widget.state.messages.length ||
        oldWidget.state.pendingText != widget.state.pendingText) {
      _scrollToEnd();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || widget.state.isSending) return;
    _input.clear();
    setState(() {});
    final ok = await widget.onSend(text);
    if (!ok && mounted && _input.text.isEmpty) {
      _input.text = text;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final ended = state.status == LiveChatStatus.ended;
    final notice = _notice(state);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFFFF4D6),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            _emergencyNote,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF7A5A12),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              for (final m in state.messages) _MessageView(message: m),
              if (state.pendingText != null)
                _Bubble(
                  text: state.pendingText!,
                  mine: true,
                  caption: 'Sending…',
                  faded: true,
                ),
            ],
          ),
        ),
        if (notice != null || state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: Text(
              state.errorMessage ?? notice!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: state.errorMessage != null
                    ? AppColors.danger
                    : AppColors.inkMuted,
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
            child: ended
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onBackToAssistant,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Back to assistant'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: widget.onNewChat,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.forest,
                            minimumSize: const Size.fromHeight(48),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Start new chat'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'Type a message…',
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        onPressed:
                            _input.text.trim().isEmpty || state.isSending
                                ? null
                                : _send,
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
          ),
        ),
      ],
    );
  }

  /// Same status lines as the website widget.
  static String? _notice(LiveChatUiState state) {
    return switch (state.status) {
      LiveChatStatus.waiting => state.fallback
          ? 'Our team is busy right now. Leave your message here and we will '
              'reply by email.'
          : 'Waiting for a team member to join…',
      LiveChatStatus.active => state.staffName.isNotEmpty
          ? 'You are chatting with ${state.staffName}.'
          : null,
      LiveChatStatus.ended => 'This chat has ended.',
      LiveChatStatus.none => null,
    };
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message});

  final LiveChatMessage message;

  @override
  Widget build(BuildContext context) {
    switch (message.sender) {
      case LiveChatSender.system:
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F4E8),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text(
              message.body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF1F6B3A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      case LiveChatSender.visitor:
        return _Bubble(text: message.body, mine: true, caption: message.time);
      case LiveChatSender.staff:
        final caption = [
          if (message.author.isNotEmpty) message.author,
          if (message.time.isNotEmpty) message.time,
        ].join(' · ');
        return _Bubble(text: message.body, mine: false, caption: caption);
    }
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.mine,
    this.caption = '',
    this.faded = false,
  });

  final String text;
  final bool mine;
  final String caption;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    return Opacity(
      opacity: faded ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: mine ? AppColors.forest : const Color(0xFFE8ECEE),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Text(
                text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: mine ? Colors.white : AppColors.ink,
                ),
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                caption,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
