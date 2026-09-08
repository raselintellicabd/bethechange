import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/widgets/app_button.dart';
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
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
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
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
          ),
        );

    if (!mounted) return;
    if (ok) {
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks — your message was sent successfully.'),
        ),
      );
    }
  }

  Future<void> _callClinic() async {
    final opened = await ref
        .read(externalLinkHandlerProvider)
        .openExternal(AppConstants.clinicPhoneTel);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the phone dialer.')),
    );
  }

  Future<void> _openDirections() async {
    final query = Uri.encodeComponent(
      '${AppConstants.clinicAddressLine1}, ${AppConstants.clinicAddressLine2}',
    );
    final opened = await ref
        .read(externalLinkHandlerProvider)
        .openExternal('https://maps.google.com/?q=$query');
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open directions.')),
    );
  }

  Widget _kv(String label, String value, {VoidCallback? onTap}) {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Text('Clinic', style: AppTextStyles.titleLarge),
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
                Text(AppConstants.clinicName, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _kv(
                  'Address',
                  '${AppConstants.clinicAddressLine1}\n${AppConstants.clinicAddressLine2}',
                ),
                _kv('Hours', AppConstants.clinicHours),
                _kv(
                  'Phone',
                  AppConstants.clinicPhoneDisplay,
                  onTap: _callClinic,
                ),
                _kv('Fax', AppConstants.clinicFaxDisplay),
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  label: 'Get directions',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.directions_outlined,
                  onPressed: _openDirections,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Send a message', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Share your question and our team will follow up.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return 'Phone is required';
                    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Subject is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Message is required';
                    }
                    if (value.trim().length < 10) {
                      return 'Please add a bit more detail';
                    }
                    return null;
                  },
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      label: 'Retry',
                      variant: AppButtonVariant.text,
                      expand: false,
                      onPressed: state.isSubmitting ? null : _submit,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Send message',
                  isLoading: state.isSubmitting,
                  expand: true,
                  onPressed: state.isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
