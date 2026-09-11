import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/models/content_block.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/appointment_cta_bar.dart';
import '../../../../core/widgets/bullet_or_icon_list_section.dart';
import '../../../../core/widgets/content_block_view.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/image_with_caption.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/recommended_books_section.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../features/appointment/domain/models/source_context.dart';
import '../../../blog/domain/models/blog_html.dart';
import '../../../blog/presentation/widgets/blog_html_view.dart';
import '../../domain/models/condition.dart';
import '../../domain/models/condition_section.dart';
import '../providers/conditions_providers.dart';

class ConditionDetailScreen extends ConsumerWidget {
  const ConditionDetailScreen({super.key, required this.conditionId});

  final String conditionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionAsync = ref.watch(conditionByIdProvider(conditionId));

    return conditionAsync.when(
      loading: () => Scaffold(
        appBar: AppAppBar.text('Condition'),
        body: const LoadingIndicator(message: 'Loading condition...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppAppBar.text('Condition'),
        body: ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(conditionByIdProvider(conditionId)),
        ),
      ),
      data: (condition) => _ConditionDetailBody(condition: condition),
    );
  }
}

class _ConditionDetailBody extends StatelessWidget {
  const _ConditionDetailBody({required this.condition});

  final Condition condition;

  SourceContext get _sourceContext => SourceContext(
        type: SourceContextType.condition,
        id: condition.routeId,
        name: condition.name,
      );

  String get _appointmentLabel {
    final label = condition.ctaLabel?.trim();
    if (label == null || label.isEmpty) return 'Request an appointment';
    return label;
  }

  bool get _showQuote {
    final quote = condition.quote?.trim() ?? '';
    if (quote.isEmpty) return false;
    if (condition.articleBody.contains(quote)) return false;
    return !condition.sections.any(
      (section) => section.title.trim().toLowerCase() == quote.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useSections = condition.sections.isNotEmpty;
    final approach = condition.integrativeApproach;
    final intro = blogContentBlocks(
      contentHtml: condition.contentHtml,
      subtitle: condition.summary,
    );
    final chipLabels = <String>[
      if (!useSections && condition.symptoms.isNotEmpty) 'Symptoms',
      if (!useSections && condition.treatmentMethods.isNotEmpty) 'Treatments',
      if (!useSections && condition.benefits.isNotEmpty) 'Benefits',
    ];

    return Scaffold(
      appBar: AppAppBar(title: Text(condition.name)),
      body: ListView(
        children: [
          _ConditionHero(condition: condition),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(condition.summary, style: theme.textTheme.titleMedium),
          ),
          if (_showQuote) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                condition.quote!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppointmentCtaBar(
              sourceContext: _sourceContext,
              label: _appointmentLabel,
            ),
          ),
          if (chipLabels.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ChipRow(labels: chipLabels),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (useSections) ...[
                  if (intro.isNotEmpty) ...[
                    BlogHtmlView(blocks: intro),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  for (final section in condition.sections)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _ConditionSectionView(section: section),
                    ),
                ] else ...[
                if (condition.articleBody.trim().isNotEmpty ||
                    condition.overviewImageUrl != null) ...[
                  const SectionHeader(title: 'Overview'),
                  if (condition.overviewImageUrl != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SectionImage(imageUrl: condition.overviewImageUrl!),
                  ],
                  if (condition.articleBody.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      condition.articleBody,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ],
                if (condition.symptoms.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  BulletOrIconListSection(
                    title: condition.symptomsSectionTitle,
                    imageUrl: condition.symptomsImageUrl,
                    items: condition.symptoms,
                    fallbackIcon: Icons.healing_outlined,
                  ),
                ],
                if (condition.contributingFactors.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  BulletOrIconListSection(
                    title: condition.factorsSectionTitle,
                    imageUrl: condition.factorsImageUrl,
                    items: condition.contributingFactors,
                    fallbackIcon: Icons.warning_amber_outlined,
                  ),
                ],
                if (approach != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ContentBlockView(
                    block: ContentBlock(
                      title: condition.integrativeApproachTitle,
                      body: approach.body,
                      imageUrl: approach.imageUrl,
                    ),
                  ),
                ],
                if (condition.benefits.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  BulletOrIconListSection(
                    title: condition.benefitsTitle,
                    items: condition.benefits,
                    fallbackIcon: Icons.verified_outlined,
                  ),
                ],
                if (condition.treatmentMethods.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionHeader(title: condition.treatmentTitle),
                  const SizedBox(height: AppSpacing.sm),
                  for (final method in condition.treatmentMethods) ...[
                    _ImageTextCard(
                      title: method.label,
                      body: method.description,
                      imageUrl: method.iconUrl,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
                if (condition.recommendedBooks.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  RecommendedBooksSection(
                    books: condition.recommendedBooks,
                    title: condition.booksTitle ?? 'Recommended Books',
                    subtitle: condition.booksSubtitle,
                  ),
                ],
                if (condition.gettingStarted.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Getting started'),
                  const SizedBox(height: AppSpacing.sm),
                  for (final step in condition.gettingStarted) ...[
                    _ImageTextCard(
                      title: step.label,
                      body: step.description,
                      imageUrl: step.iconUrl,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
                ],
                const SizedBox(height: AppSpacing.lg),
                AppointmentCtaBar(
                  sourceContext: _sourceContext,
                  label: _appointmentLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionSectionView extends StatelessWidget {
  const _ConditionSectionView({required this.section});

  final ConditionSection section;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final image = section.imageUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;
    final cards = section.isChipGroup
        ? const <ConditionSectionItem>[]
        : section.items.where((item) => item.title.trim().isNotEmpty).toList();
    final bookItems = section.isBooks ? cards : const <ConditionSectionItem>[];
    final stackedCards =
        section.isBooks ? const <ConditionSectionItem>[] : cards;

    final text = blocks.isEmpty
        ? const SizedBox.shrink()
        : BlogHtmlView(blocks: blocks);
    final imageWidget = hasImage
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SectionImage(imageUrl: image),
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title.trim().isNotEmpty) ...[
          SectionHeader(title: section.title),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (section.imageOnRight) ...[
          text,
          if (blocks.isNotEmpty && hasImage) const SizedBox(height: AppSpacing.sm),
          imageWidget,
        ] else ...[
          imageWidget,
          text,
        ],
        if (section.isChipGroup) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in section.items)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sageLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
            ],
          ),
        ],
        if (bookItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bookItems.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 220,
                  height: 320,
                  child: _SectionItemCard(item: bookItems[index], compact: true),
                );
              },
            ),
          ),
        ],
        if (stackedCards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final item in stackedCards) ...[
            _SectionItemCard(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _SectionItemCard extends StatelessWidget {
  const _SectionItemCard({required this.item, this.compact = false});

  final ConditionSectionItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );
    final contactPath = item.inAppContactPath;

    final blurb = blocks
        .map((block) => switch (block) {
              BlogParagraph(:final text) => text,
              BlogHeading(:final text) => text,
              BlogBulletList(:final items) => items.join('\n'),
            })
        .where((text) => text.trim().isNotEmpty)
        .join('\n');

    return _ImageTextCard(
      title: item.title,
      imageUrl: item.imageUrl,
      compact: compact,
      child: compact
          ? (blurb.isEmpty
              ? null
              : Text(
                  blurb,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (blocks.isNotEmpty) BlogHtmlView(blocks: blocks),
                if (contactPath != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: item.linkLabel?.trim().isNotEmpty == true
                        ? item.linkLabel!.trim()
                        : 'Request an appointment',
                    variant: AppButtonVariant.text,
                    expand: false,
                    onPressed: () => context.push(AppRoutes.contact),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SectionImage extends StatelessWidget {
  const _SectionImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ImageWithCaption(imageUrl: imageUrl, height: 180);
  }
}

class _ImageTextCard extends StatelessWidget {
  const _ImageTextCard({
    required this.title,
    this.body,
    this.imageUrl,
    this.child,
    this.compact = false,
  });

  final String title;
  final String? body;
  final String? imageUrl;
  final Widget? child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null && url.isNotEmpty)
              SizedBox(
                height: compact ? 148 : 160,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: AppColors.sageLight),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: AppColors.sageLight,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: compact
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium,
                    maxLines: compact ? 3 : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 6),
                    child!,
                  ] else if (body != null && body!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(body!, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionHero extends StatelessWidget {
  const _ConditionHero({required this.condition});

  final Condition condition;

  @override
  Widget build(BuildContext context) {
    final url = condition.heroImageUrl;
    if (url == null || url.isEmpty) {
      return AppHeroBanner(
        title: condition.name,
        tag: 'Condition',
        height: 180,
        backgroundColor: AppColors.thumbPalette[
            condition.id.hashCode.abs() % AppColors.thumbPalette.length],
      );
    }

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => const ColoredBox(color: AppColors.sageLight),
            errorWidget: (_, _, _) => AppHeroBanner(
              title: condition.name,
              tag: 'Condition',
              height: 200,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xCC1F2A22)],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Text(
              condition.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
