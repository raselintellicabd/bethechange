import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/ui_kit.dart';

/// Patients hub — four tiles. Membership is intentionally omitted.
class PatientTabScreen extends ConsumerWidget {
  const PatientTabScreen({super.key});

  static const List<String> cardTitles = [
    'Patient Portal',
    'Book a service',
    'Shop',
    'FAQ',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SectionTitle('Patient resources'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Portal access, booking, supplements, and answers.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: [
              PatientTile(
                title: cardTitles[0],
                subtitle: 'Records & messages',
                icon: Icons.account_circle_outlined,
                onTap: () => _openExternal(
                  context,
                  ref,
                  AppConstants.patientPortalUrl,
                ),
              ),
              PatientTile(
                title: cardTitles[1],
                subtitle: 'Browse therapies',
                icon: Icons.medical_services_outlined,
                onTap: () => context.go(AppRoutes.exploreServices),
              ),
              PatientTile(
                title: cardTitles[2],
                subtitle: 'Fullscript shop',
                icon: Icons.shopping_bag_outlined,
                onTap: () => _openExternal(
                  context,
                  ref,
                  AppConstants.shopSupplementsUrl,
                ),
              ),
              PatientTile(
                title: cardTitles[3],
                subtitle: 'Common questions',
                icon: Icons.help_outline,
                onTap: () => context.push(AppRoutes.faq),
              ),
            ],
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
