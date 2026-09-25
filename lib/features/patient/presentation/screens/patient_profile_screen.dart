import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/models/patient_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_labeled_field.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  var _controllersReady = false;

  @override
  void dispose() {
    if (_controllersReady) {
      _firstName.dispose();
      _lastName.dispose();
      _email.dispose();
      _phone.dispose();
    }
    super.dispose();
  }

  void _ensureControllers(PatientUser user) {
    if (_controllersReady) return;
    _firstName = TextEditingController(text: user.firstName);
    _lastName = TextEditingController(text: user.lastName);
    _email = TextEditingController(text: user.email);
    _phone = TextEditingController(text: user.phone);
    _controllersReady = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authControllerProvider.notifier).updateProfile(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile was updated.')),
      );
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('MMM d, yyyy').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    if (!auth.isLoggedIn || user == null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppAppBar.text('Profile'),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log in to view your profile',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontFamily: GoogleFonts.workSans().fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your name, email, and phone are saved with your patient account.',
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Log in',
                onPressed: () {
                  context.push(
                    AppRoutes.loginPath(returnTo: AppRoutes.patientProfile),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    _ensureControllers(user);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar.text('My Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            'Update your contact details. Membership information below is managed by the clinic.',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthLabeledField(
                  label: 'First name',
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthLabeledField(
                  label: 'Last name',
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthLabeledField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
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
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Save profile',
                  onPressed: auth.isBusy ? null : _save,
                  isLoading: auth.isBusy,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Membership',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              fontFamily: GoogleFonts.workSans().fontFamily,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (user.upgradeSuggestion != null) ...[
            _UpgradeCard(
              suggestion: user.upgradeSuggestion!,
              onView: () => context.push(AppRoutes.membership),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _MembershipDetails(
            rows: [
              ('Membership tier', user.tierTitle),
              ('Days left', '${user.leftDays}'),
              ('Started', _formatDate(user.membershipStartedAt)),
              ('Expires', _formatDate(user.membershipExpiresAt)),
              ('Services taken', '${user.servicesTaken}'),
              ('Reward points', '${user.points}'),
              (
                'Complimentary used (this period)',
                '${user.complimentaryUsed} / ${user.complimentaryAllowance}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'View Memberships',
            onPressed: () => context.push(AppRoutes.membership),
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.suggestion,
    required this.onView,
  });

  final MembershipUpgradeSuggestion suggestion;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.sageLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: const Border(
          left: BorderSide(color: AppColors.ochre, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'UPGRADE SUGGESTION',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.ochre,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            suggestion.message,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.forest),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: suggestion.ctaLabel,
            onPressed: onView,
          ),
        ],
      ),
    );
  }
}

class _MembershipDetails extends StatelessWidget {
  const _MembershipDetails({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      rows[i].$1,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 6,
                    child: Text(
                      rows[i].$2,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
