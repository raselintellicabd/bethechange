import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: const Text('Explore'),
        centerTitle: false,
      ),
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
          itemCount: catalog.conditions.length,
          itemBuilder: (context, index) {
            final condition = catalog.conditions[index];
            return ListRowTile(
              title: condition.name,
              subtitle: condition.summary,
              thumbColor:
                  AppColors.thumbPalette[index % AppColors.thumbPalette.length],
              onTap: () => context.push(
                AppRoutes.conditionDetailPath(condition.id),
              ),
            );
          },
        );
      },
    );
  }
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
          itemCount: catalog.services.length,
          itemBuilder: (context, index) {
            final service = catalog.services[index];
            return ListRowTile(
              title: service.name,
              subtitle: service.summary,
              thumbColor: AppColors.thumbPalette[
                  (index + 3) % AppColors.thumbPalette.length],
              onTap: () => context.push(
                AppRoutes.serviceDetailPath(service.id),
              ),
            );
          },
        );
      },
    );
  }
}
