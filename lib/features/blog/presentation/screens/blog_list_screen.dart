import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/image_with_caption.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/blog_article.dart';
import '../providers/blog_providers.dart';

class BlogListScreen extends ConsumerWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(blogCatalogProvider);

    return Scaffold(
      appBar: AppAppBar.text('Blog'),
      body: catalogAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading articles...'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(blogCatalogProvider),
        ),
        data: (catalog) {
          if (catalog.articles.isEmpty) {
            return const ErrorStateWidget(
              title: 'No articles',
              message: 'Blog content is missing from the data file.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(blogCatalogProvider);
              await ref.read(blogCatalogProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: catalog.articles.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _BlogCatalogHeader(title: catalog.title);
                }
                final article = catalog.articles[index - 1];
                return _BlogArticleCard(
                  article: article,
                  thumbColor: AppColors.thumbPalette[
                      (index - 1) % AppColors.thumbPalette.length],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BlogCatalogHeader extends StatelessWidget {
  const _BlogCatalogHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final heading = _titleCase(title);
    if (heading.isEmpty) return const SizedBox.shrink();

    return Text(heading, style: AppTextStyles.titleLarge);
  }
}

String _titleCase(String input) {
  return input.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).map((word) {
    final lower = word.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }).join(' ');
}

class _BlogArticleCard extends StatelessWidget {
  const _BlogArticleCard({
    required this.article,
    required this.thumbColor,
  });

  final BlogArticle article;
  final Color thumbColor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = article.imageUrl;
    final eyebrow = [
      if (article.author != null && article.author!.isNotEmpty) article.author!,
      if (article.publishedLabel != null) article.publishedLabel!,
    ].join(' · ');

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.blogDetailPath(article.routeId)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ImageWithCaption(imageUrl: imageUrl, height: 150)
            else
              Container(
                height: 120,
                width: double.infinity,
                color: thumbColor,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow.isNotEmpty)
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        letterSpacing: 0.6,
                        color: AppColors.inkMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.subtitle,
                    style: AppTextStyles.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
