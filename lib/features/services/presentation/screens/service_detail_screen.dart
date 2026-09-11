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
                      child: _ServiceSectionView(
                        section: section,
                        skipLead: service.summary,
                      ),
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
  const _ServiceSectionView({required this.section, this.skipLead});

  final ServiceSection section;
  final String? skipLead;

  @override
  Widget build(BuildContext context) {
    final html = section.contentHtml?.trim() ?? '';
    final links = _htmlLinks(html);
    final blocks = blogContentBlocks(
      contentHtml: _withoutAnchors(html),
      body: html.isEmpty ? section.content : '',
      subtitle: skipLead,
    );
    final image = section.imageUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;
    final imageItems = section.items
        .where((item) => item.imageUrl != null && item.imageUrl!.isNotEmpty)
        .toList();
    final textItems = section.items
        .where(
          (item) =>
              (item.imageUrl == null || item.imageUrl!.isEmpty) &&
              (item.contentHtml?.trim().isNotEmpty == true ||
                  item.content.trim().isNotEmpty ||
                  item.title.trim().isNotEmpty),
        )
        .toList();

    final text = blocks.isEmpty
        ? const SizedBox.shrink()
        : BlogHtmlView(blocks: blocks);
    final imageWidget = hasImage
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ImageWithCaption(imageUrl: image),
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
        for (final link in links)
          if (_inAppPath(link.href) != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: link.label,
              variant: AppButtonVariant.outlined,
              expand: false,
              onPressed: () => context.push(_inAppPath(link.href)!),
            ),
          ],
        if (textItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final item in textItems) ...[
            if (item.title.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            BlogHtmlView(
              blocks: blogContentBlocks(
                contentHtml: item.contentHtml,
                body: item.content,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (imageItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _FeaturedTherapyGrid(items: imageItems),
        ],
      ],
    );
  }
}

class _HtmlLink {
  const _HtmlLink({required this.href, required this.label});

  final String href;
  final String label;
}

List<_HtmlLink> _htmlLinks(String html) {
  return RegExp(
    r'''<a\b[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>''',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(html).map((match) {
    final label = (match.group(2) ?? '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .trim();
    return _HtmlLink(href: match.group(1) ?? '', label: label);
  }).where((link) => link.label.isNotEmpty && link.href.isNotEmpty).toList();
}

String _withoutAnchors(String html) {
  return html.replaceAll(
    RegExp(r'<a\b[^>]*>.*?</a>', caseSensitive: false, dotAll: true),
    '',
  );
}

/// Maps clinic website links onto in-app routes. Membership stays out.
String? _inAppPath(String href) {
  final raw = href.trim();
  if (raw.isEmpty || raw.toLowerCase().contains('membership')) return null;
  final uri = Uri.tryParse(raw);
  var path = uri?.path ?? raw;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  if (path.isEmpty || path == '/' || path == '/services') {
    return AppRoutes.exploreServices;
  }
  if (path == AppRoutes.contact || path == '/contact') return AppRoutes.contact;
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.length == 1) return AppRoutes.serviceDetailPath(parts.first);
  return null;
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
