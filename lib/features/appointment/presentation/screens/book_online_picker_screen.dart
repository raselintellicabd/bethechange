import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/book_online_catalog.dart';
import '../../domain/models/book_online_offering.dart';
import '../../domain/models/source_context.dart';
import '../providers/appointment_providers.dart';

/// Filtered /book-online/ accordion for one CMS service category.
class BookOnlinePickerScreen extends ConsumerWidget {
  const BookOnlinePickerScreen({super.key, required this.sourceContext});

  final SourceContext sourceContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bookOnlineCatalogProvider);

    return Scaffold(
      appBar: const AppAppBar(title: Text('Book a service')),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'Loading services...'),
        error: (error, _) {
          final raw = error.toString();
          final message = raw.startsWith('Exception: ')
              ? raw.substring('Exception: '.length)
              : raw;
          return ErrorStateWidget(
            message: message,
            onRetry: () => ref.invalidate(bookOnlineCatalogProvider),
          );
        },
        data: (catalog) {
          final category = catalog.categoryForCmsTopic(sourceContext.id);
          if (category == null || category.offerings.isEmpty) {
            return ErrorStateWidget(
              message:
                  'No bookable offerings found for ${sourceContext.name}.',
              onRetry: () => context.push(
                AppRoutes.appointmentPath(sourceContext),
              ),
            );
          }
          return _CategoryBody(
            sourceContext: sourceContext,
            category: category,
          );
        },
      ),
    );
  }
}

class _CategoryBody extends StatefulWidget {
  const _CategoryBody({
    required this.sourceContext,
    required this.category,
  });

  final SourceContext sourceContext;
  final BookOnlineCategory category;

  @override
  State<_CategoryBody> createState() => _CategoryBodyState();
}

class _CategoryBodyState extends State<_CategoryBody> {
  String? _expandedSlug;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          category.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choose a session, then book.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.expand_less, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final offering in category.offerings) ...[
          _OfferingCard(
            offering: offering,
            expanded: _expandedSlug == offering.slug,
            onToggle: () {
              setState(() {
                _expandedSlug =
                    _expandedSlug == offering.slug ? null : offering.slug;
              });
            },
            onBook: () {
              context.push(
                AppRoutes.appointmentPath(
                  widget.sourceContext,
                  offering: offering,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _OfferingCard extends StatelessWidget {
  const _OfferingCard({
    required this.offering,
    required this.expanded,
    required this.onToggle,
    required this.onBook,
  });

  final BookOnlineOffering offering;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _Thumb(url: offering.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offering.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offering.metaLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    offering.description.isEmpty
                        ? '${offering.name} · ${offering.metaLine}'
                        : offering.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Book this service',
                    expand: true,
                    onPressed: onBook,
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.sageLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.spa_outlined, color: AppColors.forest),
    );

    if (url.isEmpty || !url.startsWith('http')) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}
