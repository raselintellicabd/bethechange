import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_labeled_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  (String, String) _splitName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final (firstName, lastName) = _splitName(_fullName.text);
    final ok = await ref.read(authControllerProvider.notifier).signup(
          firstName: firstName,
          lastName: lastName,
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    if (ok) {
      final dest = widget.returnTo;
      if (dest != null && dest.isNotEmpty) {
        context.go(dest);
      } else {
        context.pop();
      }
    }
  }

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.loginPath(returnTo: widget.returnTo));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar(
        title: Text(
          'Sign up',
          style: GoogleFonts.workSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          Text(
            'Create your account',
            style: AppTextStyles.headlineLarge.copyWith(
              fontFamily: GoogleFonts.workSans().fontFamily,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Start your personalized care plan',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthLabeledField(
                  label: 'Full name',
                  controller: _fullName,
                  hintText: 'Sarah Rahman',
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final (first, last) = _splitName(v ?? '');
                    if (first.isEmpty) return 'Full name is required';
                    if (last.isEmpty) {
                      return 'Enter first and last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AuthLabeledField(
                  label: 'Email',
                  controller: _email,
                  hintText: 'you@email.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Email is required';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AuthLabeledField(
                  label: 'Phone',
                  controller: _phone,
                  hintText: '(555) 000-0000',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AuthLabeledField(
                  label: 'Password',
                  controller: _password,
                  hintText: 'Create a password',
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!auth.isBusy) _submit();
                  },
                  validator: (v) {
                    if (v == null || v.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    auth.errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Create account',
                  onPressed: auth.isBusy ? null : _submit,
                  isLoading: auth.isBusy,
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthFooterLink(
                  prompt: 'Already a patient?',
                  actionLabel: 'Log in',
                  onTap: auth.isBusy ? null : _goToLogin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
