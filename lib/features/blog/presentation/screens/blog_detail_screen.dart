import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/image_with_caption.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/blog_article.dart';
import '../providers/blog_providers.dart';

class BlogDetailScreen extends ConsumerWidget {
  const BlogDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(blogArticleByIdProvider(articleId));

    return articleAsync.when(
      loading: () => Scaffold(
        appBar: AppAppBar.text('Article'),
        body: const LoadingIndicator(message: 'Loading article...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppAppBar.text('Article'),
        body: ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(blogArticleByIdProvider(articleId)),
        ),
      ),
      data: (article) => _BlogDetailBody(article: article),
    );
  }
}

class _BlogDetailBody extends StatelessWidget {
  const _BlogDetailBody({required this.article});

  final BlogArticle article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paragraphs = article.body
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppAppBar(title: Text(article.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          if (article.imageUrl != null && article.imageUrl!.isNotEmpty) ...[
            ImageWithCaption(imageUrl: article.imageUrl!, height: 220),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(article.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(article.subtitle, style: theme.textTheme.titleMedium),
          if (_hasMeta) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _metaLine,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Text(paragraphs[i], style: theme.textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }

  bool get _hasMeta =>
      (article.author != null && article.author!.isNotEmpty) ||
      (article.publishedAt != null && article.publishedAt!.isNotEmpty);

  String get _metaLine {
    final parts = <String>[
      if (article.author != null && article.author!.isNotEmpty) article.author!,
      if (article.publishedAt != null && article.publishedAt!.isNotEmpty)
        article.publishedAt!,
    ];
    return parts.join(' · ');
  }
}
