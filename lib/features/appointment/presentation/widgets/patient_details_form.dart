import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/patient_details.dart';

class PatientDetailsForm extends StatefulWidget {
  const PatientDetailsForm({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  final PatientDetails? initial;
  final ValueChanged<PatientDetails> onSubmit;

  @override
  State<PatientDetailsForm> createState() => _PatientDetailsFormState();
}

class _PatientDetailsFormState extends State<PatientDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _emailController = TextEditingController(text: widget.initial?.email ?? '');
    _phoneController = TextEditingController(text: widget.initial?.phone ?? '');
    _notesController = TextEditingController(text: widget.initial?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(
      PatientDetails(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Email is required';
              if (!email.contains('@') || !email.contains('.')) {
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
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Review booking',
            expand: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
