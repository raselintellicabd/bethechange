import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/models/content_block.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/appointment_cta_bar.dart';
import '../../../../core/widgets/bullet_or_icon_list_section.dart';
import '../../../../core/widgets/content_block_view.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/image_with_caption.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/recommended_books_section.dart';
import '../../../../core/widgets/section_header.dart';
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
        appBar: AppBar(title: const Text('Condition')),
        body: const LoadingIndicator(message: 'Loading condition...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Condition')),
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
        id: condition.id,
        name: condition.name,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final approach = condition.integrativeApproach;

    return Scaffold(
      appBar: AppBar(title: Text(condition.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Text(condition.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(condition.summary, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AppointmentCtaBar(sourceContext: _sourceContext),
          const SizedBox(height: AppSpacing.lg),
          if (condition.heroImageUrl != null &&
              condition.heroImageUrl!.isNotEmpty) ...[
            ImageWithCaption(imageUrl: condition.heroImageUrl!),
            const SizedBox(height: AppSpacing.lg),
          ],
          const SectionHeader(title: 'Overview'),
          const SizedBox(height: AppSpacing.sm),
          Text(condition.articleBody, style: theme.textTheme.bodyLarge),
          if (condition.symptoms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            BulletOrIconListSection(
              title: 'Common Symptoms',
              items: condition.symptoms,
              fallbackIcon: Icons.healing_outlined,
            ),
          ],
          if (condition.contributingFactors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            BulletOrIconListSection(
              title: 'Factors That Contribute',
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
            BulletOrIconListSection(
              title: condition.treatmentTitle,
              items: condition.treatmentMethods,
              fallbackIcon: Icons.medical_services_outlined,
            ),
          ],
          if (condition.recommendedBooks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            RecommendedBooksSection(books: condition.recommendedBooks),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppointmentCtaBar(sourceContext: _sourceContext),
        ],
      ),
    );
  }
}
