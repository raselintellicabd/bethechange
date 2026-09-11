import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../features/conditions/presentation/providers/conditions_providers.dart';
import '../../../../features/services/presentation/providers/services_providers.dart';

/// Explore tab with Conditions | Services segment control.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.initialSegment = 0});

  /// 0 = Conditions, 1 = Services.
  final int initialSegment;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  late int _segment;

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment.clamp(0, 1);
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSegment != widget.initialSegment) {
      _segment = widget.initialSegment.clamp(0, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.text('Explore'),
      body: Column(
        children: [
          SegmentControl(
            labels: const ['Conditions', 'Services'],
            selectedIndex: _segment,
            onChanged: (index) {
              setState(() => _segment = index);
              context.go(
                index == 0
                    ? AppRoutes.exploreConditions
                    : AppRoutes.exploreServices,
              );
            },
          ),
          Expanded(
            child: _segment == 0
                ? const _ConditionsExploreList()
                : const _ServicesExploreList(),
          ),
        ],
      ),
    );
  }
}

class _ConditionsExploreList extends ConsumerWidget {
  const _ConditionsExploreList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(conditionsCatalogProvider);

    return catalogAsync.when(
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

        return ListView.builder(
          itemCount: catalog.conditions.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CatalogIntro(
                title: catalog.title,
                content: catalog.content,
              );
            }
            final condition = catalog.conditions[index - 1];
            return ListRowTile(
              large: true,
              title: condition.name,
              subtitle: condition.summary,
              thumbColor:
                  AppColors.thumbPalette[index % AppColors.thumbPalette.length],
              leading: _ExploreThumb(
                imageUrl: condition.heroImageUrl,
                color: AppColors
                    .thumbPalette[(index - 1) % AppColors.thumbPalette.length],
              ),
              onTap: () => context.push(
                AppRoutes.conditionDetailPath(condition.routeId),
              ),
            );
          },
        );
      },
    );
  }
}

class _CatalogIntro extends StatelessWidget {
  const _CatalogIntro({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final heading = _titleCase(title);
    if (heading.isEmpty && content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading.isNotEmpty)
            Text(heading, style: AppTextStyles.titleLarge),
          if (content.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(content.trim(), style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _ExploreThumb extends StatelessWidget {
  const _ExploreThumb({required this.color, this.imageUrl});

  final String? imageUrl;
  final Color color;

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _size,
        height: _size,
        child: url == null || url.isEmpty
            ? ColoredBox(color: color)
            : CachedNetworkImage(
                imageUrl: url,
                width: _size,
                height: _size,
                fit: BoxFit.cover,
                memCacheWidth: 216,
                placeholder: (_, _) => ColoredBox(color: color),
                errorWidget: (_, _, _) => ColoredBox(
                  color: color,
                  child: const Icon(Icons.image_outlined, color: Colors.white),
                ),
              ),
      ),
    );
  }
}

String _titleCase(String input) {
  return input.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).map((word) {
    final lower = word.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }).join(' ');
}

class _ServicesExploreList extends ConsumerWidget {
  const _ServicesExploreList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(servicesCatalogProvider);

    return catalogAsync.when(
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

        return ListView.builder(
          itemCount: catalog.services.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CatalogIntro(
                title: catalog.title,
                content: catalog.content,
              );
            }
            final service = catalog.services[index - 1];
            return ListRowTile(
              large: true,
              title: service.name,
              subtitle: service.summary,
              thumbColor: AppColors.thumbPalette[
                  (index + 2) % AppColors.thumbPalette.length],
              leading: _ExploreThumb(
                imageUrl: service.heroImageUrl,
                color: AppColors
                    .thumbPalette[(index + 2) % AppColors.thumbPalette.length],
              ),
              onTap: () => context.push(
                AppRoutes.serviceDetailPath(service.routeId),
              ),
            );
          },
        );
      },
    );
  }
}
