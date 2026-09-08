import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/conditions_providers.dart';
import '../utils/condition_icons.dart';

class ConditionsListScreen extends ConsumerWidget {
  const ConditionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(conditionsCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conditions')),
      body: catalogAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading conditions...'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(conditionsCatalogProvider),
        ),
        data: (catalog) {
          if (catalog.conditions.isEmpty) {
            return const ErrorStateWidget(
              title: 'No conditions',
              message: 'Condition content is missing from the data file.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: catalog.conditions.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final condition = catalog.conditions[index];
              return AppCard(
                onTap: () => context.push(
                  AppRoutes.conditionDetailPath(condition.id),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceMuted,
                      child: Icon(
                        conditionIconFor(condition.id),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            condition.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            condition.summary,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
