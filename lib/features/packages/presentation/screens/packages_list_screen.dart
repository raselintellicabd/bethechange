import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/package_bundle.dart';
import '../providers/packages_providers.dart';

/// Published packages catalog — entry from Patients tab.
class PackagesListScreen extends ConsumerWidget {
  const PackagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(packageCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar(
        title: const Text('Available packages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: catalogAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading packages…'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(packageCatalogProvider),
        ),
        data: (catalog) {
          if (catalog.results.isEmpty) {
            return const ErrorStateWidget(
              title: 'No packages',
              message: 'There are no packages available right now.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            itemCount: catalog.results.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              return _PackageCard(bundle: catalog.results[index]);
            },
          );
        },
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.bundle});

  final PackageBundle bundle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(bundle.name, style: AppTextStyles.titleMedium),
            if (bundle.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                bundle.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            for (final item in bundle.items) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: AppColors.forest),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.serviceName} · ${item.durationDisplay}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    Text(
                      item.priceDisplay,
                      style: AppTextStyles.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bundle.quote.discountCents > 0)
                        Text(
                          bundle.quote.listAmountDisplay,
                          style: AppTextStyles.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      Text(
                        bundle.quote.payableDisplay,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Buy package',
                  expand: false,
                  onPressed: () => context.push(
                    AppRoutes.packageBookPath(bundle.slug),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
