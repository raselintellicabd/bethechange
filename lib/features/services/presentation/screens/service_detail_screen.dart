import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/models/content_block.dart';
import '../../../../core/router/app_routes.dart';
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
        appBar: AppAppBar.text('Service'),
        body: const LoadingIndicator(message: 'Loading service...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppAppBar.text('Service'),
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
        id: service.routeId,
        name: service.name,
      );

  String get _appointmentLabel {
    final label = service.ctaLabel?.trim();
    if (label == null || label.isEmpty) return 'Request an appointment';
    return label;
  }

  bool get _showQuote {
    final quote = service.quote?.trim() ?? '';
    if (quote.isEmpty) return false;
    if (service.articleBody.contains(quote)) return false;
    return !service.sections.any((section) => section.content.contains(quote));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final howItWorks = service.howItWorks;
    final whatToExpect = service.whatToExpect;
    final useSections = service.sections.isNotEmpty;
    final chipLabels = <String>[
      if (!useSections && service.benefits.isNotEmpty) 'Benefits',
      if (!useSections && service.addressedConcerns.isNotEmpty) 'Concerns',
      if (!useSections && whatToExpect != null) 'What to expect',
    ];

    return Scaffold(
      appBar: AppAppBar(title: Text(service.name)),
      body: ListView(
        children: [
          _ServiceHero(service: service),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(service.summary, style: theme.textTheme.titleMedium),
          ),
          if (_showQuote) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                service.quote!,
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
                if (useSections)
                  ...service.sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: _ServiceSectionView(section: section),
                    ),
                  )
                else ...[
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
                ],
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

class _ServiceSectionView extends StatelessWidget {
  const _ServiceSectionView({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageItems = section.items
        .where((item) => item.imageUrl != null && item.imageUrl!.isNotEmpty)
        .toList();
    final textItems = section.items.where((item) => item.lines.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title.trim().isNotEmpty) ...[
          SectionHeader(title: section.title),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (section.imageUrl != null && section.imageUrl!.isNotEmpty) ...[
          ImageWithCaption(imageUrl: section.imageUrl!),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (section.content.trim().isNotEmpty)
          Text(section.content.trim(), style: theme.textTheme.bodyLarge),
        if (imageItems.isNotEmpty) ...[
          if (section.content.trim().isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          _FeaturedTherapyGrid(items: imageItems),
        ],
        if (textItems.isNotEmpty && imageItems.isEmpty) ...[
          if (section.content.trim().isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          for (final item in textItems) ...[
            if (item.title.trim().isNotEmpty)
              Text(item.title, style: theme.textTheme.titleSmall),
            for (final line in item.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(line, style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _FeaturedTherapyGrid extends StatelessWidget {
  const _FeaturedTherapyGrid({required this.items});

  final List<ServiceSectionItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _FeaturedTherapyTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _FeaturedTherapyTile extends StatelessWidget {
  const _FeaturedTherapyTile({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final slug = item.linkSlug;
    final label = item.title.trim().isNotEmpty
        ? item.title.trim()
        : _labelFromSlug(slug);
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AspectRatio(
        aspectRatio: 1.15,
        child: CachedNetworkImage(
          imageUrl: item.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => const ColoredBox(color: AppColors.sageLight),
          errorWidget: (_, _, _) => const ColoredBox(
            color: AppColors.sageLight,
            child: Icon(Icons.image_outlined),
          ),
        ),
      ),
    );

    return Semantics(
      button: slug != null,
      label: label.isEmpty ? 'Featured therapy' : label,
      child: InkWell(
        onTap: slug == null
            ? null
            : () => context.push(AppRoutes.serviceDetailPath(slug)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: image,
      ),
    );
  }

  String _labelFromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return '';
    return slug
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _ServiceHero extends StatelessWidget {
  const _ServiceHero({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final url = service.heroImageUrl;
    if (url == null || url.isEmpty) {
      return AppHeroBanner(
        title: service.name,
        tag: 'Therapy',
        height: 180,
        backgroundColor: AppColors.thumbPalette[
            (service.id.hashCode.abs() + 3) % AppColors.thumbPalette.length],
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
              title: service.name,
              tag: 'Therapy',
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
              service.name,
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
