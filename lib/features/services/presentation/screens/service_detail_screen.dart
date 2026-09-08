import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/models/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/appointment_cta_bar.dart';
import '../../../../core/widgets/bullet_or_icon_list_section.dart';
import '../../../../core/widgets/content_block_view.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/recommended_books_section.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../features/appointment/domain/models/source_context.dart';
import '../../domain/models/service.dart';
import '../providers/services_providers.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceByIdProvider(serviceId));

    return serviceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: const LoadingIndicator(message: 'Loading service...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Service')),
        body: ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(serviceByIdProvider(serviceId)),
        ),
      ),
      data: (service) => _ServiceDetailBody(service: service),
    );
  }
}

class _ServiceDetailBody extends StatelessWidget {
  const _ServiceDetailBody({required this.service});

  final Service service;

  SourceContext get _sourceContext => SourceContext(
        type: SourceContextType.service,
        id: service.id,
        name: service.name,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final howItWorks = service.howItWorks;
    final whatToExpect = service.whatToExpect;
    final chipLabels = <String>[
      if (service.benefits.isNotEmpty) 'Benefits',
      if (service.addressedConcerns.isNotEmpty) 'Concerns',
      if (whatToExpect != null) 'What to expect',
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: AppColors.forest,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: AppHeroBanner(
                title: service.name,
                tag: 'Therapy',
                height: 220,
                backgroundColor: AppColors.thumbPalette[
                    (service.id.hashCode.abs() + 3) %
                        AppColors.thumbPalette.length],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(service.summary, style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AppointmentCtaBar(sourceContext: _sourceContext),
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
                      const SectionHeader(title: 'Overview'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(service.articleBody, style: theme.textTheme.bodyLarge),
                      if (howItWorks != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        ContentBlockView(
                          block: ContentBlock(
                            title: service.howItWorksTitle,
                            body: howItWorks.body,
                            imageUrl: howItWorks.imageUrl,
                          ),
                        ),
                      ],
                      if (service.benefits.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        BulletOrIconListSection(
                          title: service.benefitsTitle,
                          items: service.benefits,
                          fallbackIcon: Icons.verified_outlined,
                        ),
                      ],
                      if (service.addressedConcerns.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        BulletOrIconListSection(
                          title: service.addressedConcernsTitle,
                          items: service.addressedConcerns,
                          fallbackIcon: Icons.checklist_outlined,
                        ),
                      ],
                      if (whatToExpect != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        ContentBlockView(
                          block: ContentBlock(
                            title: service.whatToExpectTitle,
                            body: whatToExpect.body,
                            imageUrl: whatToExpect.imageUrl,
                          ),
                        ),
                      ],
                      if (service.recommendedBooks.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        RecommendedBooksSection(
                          books: service.recommendedBooks,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppointmentCtaBar(sourceContext: _sourceContext),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
