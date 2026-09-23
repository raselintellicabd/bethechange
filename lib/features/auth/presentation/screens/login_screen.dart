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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.returnTo});

  final String? returnTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authControllerProvider.notifier).login(
          email: _email.text.trim(),
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

  void _goToSignup() {
    context.push(AppRoutes.signupPath(returnTo: widget.returnTo));
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar(
        title: Text(
          'Log in',
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
          Center(
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Welcome back',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              fontFamily: GoogleFonts.workSans().fontFamily,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Log in to manage your care',
            textAlign: TextAlign.center,
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
                  label: 'Password',
                  controller: _password,
                  hintText: '••••••••',
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!auth.isBusy) _submit();
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: auth.isBusy
                        ? null
                        : () => _showComingSoon('Password reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ochre,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.ochre,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    auth.errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Log in',
                  onPressed: auth.isBusy ? null : _submit,
                  isLoading: auth.isBusy,
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthFooterLink(
                  prompt: 'New here?',
                  actionLabel: 'Sign up',
                  onTap: auth.isBusy ? null : _goToSignup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
