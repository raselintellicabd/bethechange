import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/image_with_caption.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/blog_article.dart';
import '../../domain/models/blog_html.dart';
import '../providers/blog_providers.dart';
import '../widgets/blog_html_view.dart';

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
    final blocks = blogContentBlocks(
      contentHtml: article.contentHtml,
      body: article.body,
      subtitle: article.subtitle,
    );

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
          if (blocks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            BlogHtmlView(blocks: blocks),
          ],
        ],
      ),
    );
  }

  bool get _hasMeta =>
      (article.author != null && article.author!.isNotEmpty) ||
      article.publishedLabel != null;

  String get _metaLine {
    final parts = <String>[
      if (article.author != null && article.author!.isNotEmpty) article.author!,
      if (article.publishedLabel != null) article.publishedLabel!,
    ];
    return parts.join(' · ');
  }
}
