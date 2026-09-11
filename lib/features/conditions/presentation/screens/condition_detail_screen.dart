import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/models/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_app_bar.dart';
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
import '../../domain/models/condition.dart';
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
    return !condition.articleBody.contains(quote);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final approach = condition.integrativeApproach;
    final chipLabels = <String>[
      if (condition.symptoms.isNotEmpty) 'Symptoms',
      if (condition.treatmentMethods.isNotEmpty) 'Treatments',
      if (condition.benefits.isNotEmpty) 'Benefits',
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
  });

  final String title;
  final String? body;
  final String? imageUrl;

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
                height: 160,
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
                  Text(title, style: theme.textTheme.titleMedium),
                  if (body != null && body!.trim().isNotEmpty) ...[
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
