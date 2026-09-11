import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/services_providers.dart';
import '../utils/service_icons.dart';

class ServicesListScreen extends ConsumerWidget {
  const ServicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(servicesCatalogProvider);

    return Scaffold(
      appBar: AppAppBar.text('Services'),
      body: catalogAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading services...'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(servicesCatalogProvider),
        ),
        data: (catalog) {
          if (catalog.services.isEmpty) {
            return const ErrorStateWidget(
              title: 'No services',
              message: 'Service content is missing from the data file.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: catalog.services.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final service = catalog.services[index];
              return AppCard(
                semanticLabel: 'Open ${service.name} details',
                onTap: () => context.push(
                  AppRoutes.serviceDetailPath(service.routeId),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: service.heroImageUrl == null
                            ? ColoredBox(
                                color: AppColors.surfaceMuted,
                                child: Icon(
                                  serviceIconFor(service.id),
                                  color: AppColors.primary,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: service.heroImageUrl!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => const ColoredBox(
                                  color: AppColors.surfaceMuted,
                                ),
                                errorWidget: (_, _, _) => Icon(
                                  serviceIconFor(service.id),
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            service.summary,
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
