import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/contact_page.dart';
import '../../domain/models/contact_request.dart';
import '../providers/contact_providers.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(contactControllerProvider.notifier).submit(
          ContactRequest(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            message: _messageController.text.trim(),
          ),
        );

    if (!mounted || !ok) return;
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _messageController.clear();
  }

  Future<void> _openExternal(String url, String failureMessage) async {
    if (url.trim().isEmpty) return;
    final opened =
        await ref.read(externalLinkHandlerProvider).openExternal(url);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(contactPageProvider);
    final state = ref.watch(contactControllerProvider);

    return Scaffold(
      appBar: AppAppBar.text('Contact'),
      body: pageAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading…'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(contactPageProvider),
        ),
        data: (page) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            _LocationCard(
              location: page.location,
              onCall: () => _openExternal(
                page.location.dialUrl,
                'Could not open the phone dialer.',
              ),
              onDirections: () => _openExternal(
                page.location.directionsUrl,
                'Could not open directions.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.submission != null)
              _ContactSuccessCard(
                result: state.submission!,
                onSendAnother: () {
                  ref.read(contactControllerProvider.notifier).clearFeedback();
                },
              )
            else
              _ContactForm(
                formKey: _formKey,
                form: page.form,
                nameController: _nameController,
                emailController: _emailController,
                phoneController: _phoneController,
                messageController: _messageController,
                errorMessage: state.errorMessage,
                isSubmitting: state.isSubmitting,
                onSubmit: _submit,
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.onCall,
    required this.onDirections,
  });

  final ContactLocation location;
  final VoidCallback onCall;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (location.title.isNotEmpty)
          Text(location.title, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (location.name.isNotEmpty)
                Text(location.name, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _kv(
                'Address',
                [location.addressLine1, location.addressLine2]
                    .where((line) => line.trim().isNotEmpty)
                    .join('\n'),
              ),
              _kv('Hours', location.hours),
              _kv('Phone', location.phone, onTap: location.dialUrl.isEmpty ? null : onCall),
              _kv('Fax', location.fax),
              if (location.directionsUrl.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: 'Get directions',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.directions_outlined,
                  onPressed: onDirections,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value, {VoidCallback? onTap}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final valueText = Text(
      value,
      style: AppTextStyles.bodyMedium.copyWith(
        color: onTap != null ? AppColors.forest : AppColors.ink,
        decoration: onTap != null ? TextDecoration.underline : null,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: onTap == null
                ? valueText
                : InkWell(onTap: onTap, child: valueText),
          ),
        ],
      ),
    );
  }
}

class _ContactForm extends StatelessWidget {
  const _ContactForm({
    required this.formKey,
    required this.form,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.messageController,
    required this.errorMessage,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final ContactFormContent form;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController messageController;
  final String? errorMessage;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (form.eyebrow.isNotEmpty)
            Text(
              form.eyebrow.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 0.6,
                color: AppColors.inkMuted,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(form.heading, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (final field in form.fields) ...[
            _field(field),
            const SizedBox(height: AppSpacing.md),
          ],
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: 'Retry',
                variant: AppButtonVariant.text,
                expand: false,
                onPressed: isSubmitting ? null : onSubmit,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton(
            label: form.submitLabel,
            isLoading: isSubmitting,
            expand: true,
            onPressed: isSubmitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }

  Widget _field(ContactFormField field) {
    return switch (field.name) {
      'name' => TextFormField(
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: field.label),
          validator: (value) => _required(field, value),
        ),
      'email' => TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: field.label),
          validator: (value) {
            final required = _required(field, value);
            if (required != null) return required;
            final email = value?.trim() ?? '';
            if (email.isNotEmpty &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
      'phone' => TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: field.label),
          validator: (value) {
            final required = _required(field, value);
            if (required != null) return required;
            final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
            if (digits.isNotEmpty && digits.length < 10) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      'message' => TextFormField(
          controller: messageController,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: field.label,
            alignLabelWithHint: true,
          ),
          validator: (value) => _required(field, value),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  String? _required(ContactFormField field, String? value) {
    if (!field.required) return null;
    if (value == null || value.trim().isEmpty) {
      return '${field.label} is required';
    }
    return null;
  }
}

class _ContactSuccessCard extends StatelessWidget {
  const _ContactSuccessCard({
    required this.result,
    required this.onSendAnother,
  });

  final ContactSubmissionResult result;
  final VoidCallback onSendAnother;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
          const SizedBox(height: AppSpacing.sm),
          Text('Message sent', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            result.name.isEmpty
                ? 'Thanks. We received your message and will follow up.'
                : 'Thanks, ${result.name}. We received your message and will follow up.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _receiptRow('Email', result.email),
          _receiptRow('Phone', result.phone),
          _receiptRow('Reference', result.id),
          _receiptRow('Status', result.statusLabel),
          if (result.message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Your message', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(result.message, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Send another message',
            variant: AppButtonVariant.outlined,
            expand: true,
            onPressed: onSendAnother,
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
