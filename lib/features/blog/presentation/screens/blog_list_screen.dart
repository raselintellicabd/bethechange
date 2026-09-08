import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
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
      appBar: AppBar(title: const Text('Blog')),
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
              itemCount: catalog.articles.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final article = catalog.articles[index];
                return _BlogArticleCard(article: article);
              },
            ),
          );
        },
      ),
    );
  }
}

class _BlogArticleCard extends StatelessWidget {
  const _BlogArticleCard({required this.article});

  final BlogArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = article.imageUrl;

    return AppCard(
      onTap: () => context.push(AppRoutes.blogDetailPath(article.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            ImageWithCaption(imageUrl: imageUrl, height: 160)
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.article_outlined, color: AppColors.primary),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(article.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            article.subtitle,
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (article.publishedAt != null &&
              article.publishedAt!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              article.publishedAt!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
