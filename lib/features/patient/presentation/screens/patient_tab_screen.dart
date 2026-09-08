import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/widgets/app_card.dart';

/// Patient area — exactly three actions. Membership is intentionally omitted.
class PatientTabScreen extends ConsumerWidget {
  const PatientTabScreen({super.key});

  static const List<String> cardTitles = [
    'Patient Portal',
    'Book a Service',
    'Shop Supplements',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.faq),
            child: const Text('FAQ'),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.contact),
            child: const Text('Contact'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Patient resources',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Access your portal, explore services, or order supplements.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PatientActionCard(
            title: cardTitles[0],
            subtitle: 'Sign in to view records and messages.',
            icon: Icons.account_circle_outlined,
            onTap: () => _openExternal(
              context,
              ref,
              AppConstants.patientPortalUrl,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PatientActionCard(
            title: cardTitles[1],
            subtitle: 'Browse clinic services and request an appointment.',
            icon: Icons.medical_services_outlined,
            onTap: () => context.go(AppRoutes.services),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PatientActionCard(
            title: cardTitles[2],
            subtitle: 'Order recommended supplements on Fullscript.',
            icon: Icons.shopping_bag_outlined,
            onTap: () => _openExternal(
              context,
              ref,
              AppConstants.shopSupplementsUrl,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternal(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    final opened =
        await ref.read(externalLinkHandlerProvider).openExternal(url);
    if (!context.mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the link. Please try again.'),
        ),
      );
    }
  }
}

class _PatientActionCard extends StatelessWidget {
  const _PatientActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.surfaceMuted,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
