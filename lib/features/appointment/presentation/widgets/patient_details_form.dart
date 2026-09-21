import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/models/patient_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/consultation_mode.dart';
import '../../domain/models/patient_details.dart';

class PatientDetailsForm extends ConsumerStatefulWidget {
  const PatientDetailsForm({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  final PatientDetails? initial;
  final ValueChanged<PatientDetails> onSubmit;

  @override
  ConsumerState<PatientDetailsForm> createState() => _PatientDetailsFormState();
}

class _PatientDetailsFormState extends ConsumerState<PatientDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  ConsultationMode? _consultationMode;
  bool _forFamilyMember = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _forFamilyMember = initial?.forFamilyMember ?? false;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _emailController = TextEditingController(text: initial?.email ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _consultationMode = initial?.consultationMode;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill) return;
    _didPrefill = true;
    final user = ref.read(currentUserProvider);
    if (widget.initial != null) return;
    if (user != null && user.profileComplete && !_forFamilyMember) {
      _applyProfile(user);
    }
  }

  bool _didPrefill = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _applyProfile(PatientUser user) {
    _nameController.text = user.fullName;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
  }

  void _clearIdentity() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
  }

  void _submit(PatientUser? user, {required bool lockSelf}) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final mode = _consultationMode;
    if (mode == null) {
      setState(() {});
      return;
    }
    widget.onSubmit(
      PatientDetails(
        name: lockSelf && user != null ? user.fullName : _nameController.text.trim(),
        email: lockSelf && user != null ? user.email : _emailController.text.trim(),
        phone: lockSelf && user != null ? user.phone : _phoneController.text.trim(),
        consultationMode: mode,
        forFamilyMember: _forFamilyMember,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final canFamily = user?.canBookForFamily ?? false;
    final lockSelf = user != null &&
        user.profileComplete &&
        !_forFamilyMember;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canFamily) ...[
            Text('Who is this appointment for?', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            RadioListTile<bool>(
              title: const Text('For me'),
              value: false,
              groupValue: _forFamilyMember,
              onChanged: (v) {
                setState(() {
                  _forFamilyMember = false;
                  if (user != null) _applyProfile(user);
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('For a family member'),
              value: true,
              groupValue: _forFamilyMember,
              onChanged: (v) {
                setState(() {
                  _forFamilyMember = true;
                  _clearIdentity();
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (lockSelf) ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Using your account', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(user!.fullName),
                    Text(user.email),
                    Text(user.phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
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
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.length < 10) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Consultation mode', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          RadioListTile<ConsultationMode>(
            title: const Text('Virtual'),
            value: ConsultationMode.virtual,
            groupValue: _consultationMode,
            onChanged: (v) => setState(() => _consultationMode = v),
          ),
          RadioListTile<ConsultationMode>(
            title: const Text('In-Office'),
            value: ConsultationMode.inOffice,
            groupValue: _consultationMode,
            onChanged: (v) => setState(() => _consultationMode = v),
          ),
          if (_consultationMode == null)
            Text(
              'Select a consultation mode',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Continue',
            onPressed: () => _submit(user, lockSelf: lockSelf),
          ),
        ],
      ),
    );
  }
}
