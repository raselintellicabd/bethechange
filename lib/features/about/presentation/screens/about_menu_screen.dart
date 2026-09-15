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
import '../../domain/models/about_content.dart';
import '../providers/about_providers.dart';

/// About catalog — pages from `GET /api/v1/about/`.
class AboutMenuScreen extends ConsumerWidget {
  const AboutMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar.text('About'),
      body: aboutAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading About...'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(aboutContentProvider),
        ),
        data: (content) {
          if (content.pages.isEmpty) {
            return const ErrorStateWidget(
              title: 'No content',
              message: 'About pages are missing from the API.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Text(
                content.title,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn about our practice, philosophy, and care process.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < content.pages.length; i++) ...[
                _AboutPageCard(
                  page: content.pages[i],
                  accent: AppColors.thumbPalette[i % AppColors.thumbPalette.length],
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AboutPageCard extends StatelessWidget {
  const _AboutPageCard({required this.page, required this.accent});

  final AboutPageSummary page;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.aboutSectionPath(page.slug)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: page.imageUrl == null
                  ? ColoredBox(color: accent.withValues(alpha: 0.35))
                  : CachedNetworkImage(
                      imageUrl: page.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          ColoredBox(color: accent.withValues(alpha: 0.35)),
                      errorWidget: (_, _, _) => ColoredBox(
                        color: accent.withValues(alpha: 0.35),
                        child: const Icon(Icons.image_outlined),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.brandNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (page.summary != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        page.summary!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.inkMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 36),
              child: Icon(Icons.chevron_right, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
