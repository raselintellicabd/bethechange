import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/appointment_cta_bar.dart';
import '../../../../core/widgets/review_card.dart';
import '../../../../features/appointment/domain/models/source_context.dart';
import '../../../about/domain/models/review.dart';
import '../../../blog/domain/models/blog_html.dart';
import '../../../blog/presentation/widgets/blog_html_view.dart';
import '../../domain/models/service.dart';

/// Website-matched Infrared Sauna page (`/infrared-sauna-therapy/`).
/// Not shared with other service screens.
class InfraredSaunaTherapyDetailView extends StatelessWidget {
  const InfraredSaunaTherapyDetailView({super.key, required this.service});

  final Service service;

  SourceContext get _source => SourceContext(
        type: SourceContextType.service,
        id: service.routeId,
        name: service.name,
      );

  String get _ctaLabel {
    final label = service.ctaLabel?.trim();
    if (label == null || label.isEmpty) return 'Request An Appointment';
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final sections = service.sections;
    final concerns = _firstWhere(sections, _isConcerns) ?? _fallbackConcerns();
    final overview = _firstWhere(sections, _isOverview);
    final benefits = _firstWhere(sections, _isBenefits);
    final options = _firstWhere(sections, _isOptions);
    final chromo = _firstWhere(sections, _isChromotherapy);
    final gallery = sections.where(_isImageOnly).toList();
    final faq = _firstWhere(sections, _isFaq);
    final expect = _firstWhere(sections, _isExpect);

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(title: Text(service.name)),
      body: ListView(
        children: [
          _HeroHeadingLine(
            text: service.heroHeading ?? 'Infrared sauna therapy',
          ),
          if (concerns != null) _ConcernsSection(section: concerns),
          if (overview != null) _OverviewSection(section: overview),
          if (benefits != null) _BenefitsSection(section: benefits),
          if (options != null) _OptionsSection(section: options),
          if (chromo != null) _ChromotherapyAccordion(section: chromo),
          if (gallery.isNotEmpty) _GallerySection(sections: gallery),
          if (faq != null) _FaqAccordion(section: faq),
          if (expect != null)
            _ExpectSection(section: expect, source: _source),
          if (service.reviews.isNotEmpty)
            _ReviewsSection(reviews: service.reviews),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: AppointmentCtaBar(
              sourceContext: _source,
              label: _ctaLabel,
            ),
          ),
        ],
      ),
    );
  }

  ServiceSection? _fallbackConcerns() {
    if (service.addressedConcerns.isEmpty) return null;
    return ServiceSection(
      type: 'cards',
      title: service.headline ??
          'If you struggle with any of these conditions, Infrared Sauna '
              'Therapy can help!',
      items: service.addressedConcerns
          .map((item) => ServiceSectionItem(title: item.label))
          .toList(),
    );
  }

  bool _isConcerns(ServiceSection section) {
    final title = section.title.toLowerCase();
    if (title.contains('struggle') || title.contains('can help')) return true;
    if (_isOverview(section) ||
        _isBenefits(section) ||
        _isOptions(section) ||
        _isChromotherapy(section) ||
        _isFaq(section) ||
        _isExpect(section)) {
      return false;
    }
    final labelsOnly = section.items.isNotEmpty &&
        section.items.every(
          (item) =>
              item.title.trim().isNotEmpty &&
              (item.imageUrl == null || item.imageUrl!.trim().isEmpty) &&
              item.content.trim().isEmpty,
        );
    return labelsOnly && section.type.toLowerCase() == 'cards';
  }

  bool _isOverview(ServiceSection section) {
    if (_isImageOnly(section)) return false;
    final type = section.type.trim().toLowerCase();
    if (type == 'image_text') {
      return section.title.trim().isNotEmpty ||
          section.content.trim().isNotEmpty ||
          (section.contentHtml?.trim().isNotEmpty ?? false);
    }
    final image = section.imageUrl?.trim() ?? '';
    return image.isNotEmpty &&
        section.title.toLowerCase().contains('what is infrared');
  }

  bool _isImageOnly(ServiceSection section) {
    if (_isBenefits(section) ||
        _isOptions(section) ||
        _isChromotherapy(section) ||
        _isFaq(section) ||
        _isExpect(section)) {
      return false;
    }
    final image = section.imageUrl?.trim() ?? '';
    if (image.isEmpty) return false;
    return section.title.trim().isEmpty &&
        section.content.trim().isEmpty &&
        (section.contentHtml == null || section.contentHtml!.trim().isEmpty) &&
        section.items.isEmpty;
  }

  bool _isBenefits(ServiceSection section) {
    final title = section.title.toLowerCase();
    return title.contains('benefits of') ||
        (title.contains('benefits') && !title.contains('chromotherapy'));
  }

  bool _isOptions(ServiceSection section) {
    final title = section.title.toLowerCase();
    return title.contains('options') || title.contains('pricing');
  }

  bool _isChromotherapy(ServiceSection section) {
    return section.title.toLowerCase().contains('chromotherapy');
  }

  bool _isFaq(ServiceSection section) {
    final title = section.title.toLowerCase();
    return title.contains('frequently asked') || title.contains('faq');
  }

  bool _isExpect(ServiceSection section) {
    return section.title.toLowerCase().contains('what to expect');
  }

  ServiceSection? _firstWhere(
    List<ServiceSection> sections,
    bool Function(ServiceSection) test,
  ) {
    for (final section in sections) {
      if (test(section)) return section;
    }
    return null;
  }
}

class _HeroHeadingLine extends StatelessWidget {
  const _HeroHeadingLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.brandAccent, thickness: 1),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.brandAccent,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.brandAccent, thickness: 1),
          ),
        ],
      ),
    );
  }
}

class _ConcernsSection extends StatelessWidget {
  const _ConcernsSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final labels = section.items
        .map((item) => item.title.trim())
        .where((label) => label.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        children: [
          Text(
            section.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 20),
            _CheckGrid(labels: labels),
          ],
        ],
      ),
    );
  }
}

class _CheckGrid extends StatelessWidget {
  const _CheckGrid({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 14,
          children: [
            for (final label in labels)
              SizedBox(
                width: width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 10, top: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.brandAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.brandNavy,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final image = section.imageUrl?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentTitle(section.title),
          if (blocks.isNotEmpty) ...[
            const SizedBox(height: 12),
            BlogHtmlView(blocks: blocks),
          ],
          if (image != null && image.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RoundedImage(url: image, height: 220),
          ],
        ],
      ),
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final intro = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final labels = section.items
        .map((item) => item.title.trim())
        .where((label) => label.isNotEmpty)
        .toList();

    return Column(
      children: [
        CustomPaint(
          size: Size(MediaQuery.sizeOf(context).width, 36),
          painter: const _WaveDownPainter(AppColors.brandNavy),
        ),
        Container(
          width: double.infinity,
          color: AppColors.brandNavy,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              _LinedTitle(section.title),
              if (intro.isNotEmpty) ...[
                const SizedBox(height: 14),
                DefaultTextStyle(
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    height: 1.55,
                  ),
                  textAlign: TextAlign.center,
                  child: BlogHtmlView(blocks: intro),
                ),
              ],
              if (labels.isNotEmpty) ...[
                const SizedBox(height: 20),
                _BenefitCardGrid(labels: labels),
              ],
            ],
          ),
        ),
        CustomPaint(
          size: Size(MediaQuery.sizeOf(context).width, 36),
          painter: const _WaveUpPainter(AppColors.brandNavy),
        ),
      ],
    );
  }
}

class _LinedTitle extends StatelessWidget {
  const _LinedTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
      ],
    );
  }
}

class _BenefitCardGrid extends StatelessWidget {
  const _BenefitCardGrid({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final label in labels)
              SizedBox(
                width: width,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconFor(label),
                        color: AppColors.brandAccent,
                        size: 34,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _iconFor(String label) {
    final key = label.toLowerCase();
    if (key.contains('detox')) return Icons.water_drop_outlined;
    if (key.contains('pain')) return Icons.healing_outlined;
    if (key.contains('circulation')) return Icons.sync;
    if (key.contains('immune')) return Icons.shield_outlined;
    if (key.contains('weight')) return Icons.monitor_weight_outlined;
    if (key.contains('sleep')) return Icons.bedtime_outlined;
    if (key.contains('brain')) return Icons.psychology_outlined;
    if (key.contains('relax')) return Icons.spa_outlined;
    return Icons.check_circle_outline;
  }
}

class _OptionsSection extends StatelessWidget {
  const _OptionsSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final intro = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final items =
        section.items.where((item) => item.title.trim().isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Text(
            section.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (intro.isNotEmpty) ...[
            const SizedBox(height: 10),
            DefaultTextStyle(
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.brandNavy,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              child: BlogHtmlView(blocks: intro),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 18),
            for (final item in items) ...[
              _OptionCard(item: item),
              const SizedBox(height: 18),
            ],
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );
    final image = item.imageUrl?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null && image.isNotEmpty) ...[
          _RoundedImage(url: image, height: 180),
          const SizedBox(height: 12),
        ],
        Text(
          item.title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (blocks.isNotEmpty) ...[
          const SizedBox(height: 8),
          BlogHtmlView(blocks: blocks),
        ],
      ],
    );
  }
}

class _ChromotherapyAccordion extends StatefulWidget {
  const _ChromotherapyAccordion({required this.section});

  final ServiceSection section;

  @override
  State<_ChromotherapyAccordion> createState() =>
      _ChromotherapyAccordionState();
}

class _ChromotherapyAccordionState extends State<_ChromotherapyAccordion> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final intro = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final items =
        section.items.where((item) => item.title.trim().isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _expanded ? Icons.remove : Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.brandNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (intro.isNotEmpty) ...[
                      BlogHtmlView(blocks: intro),
                      const SizedBox(height: 14),
                    ],
                    for (var i = 0; i < items.length; i++) ...[
                      _ColorItem(item: items[i]),
                      if (i < items.length - 1)
                        const Divider(height: 28, color: Color(0xFFE2E6EA)),
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

class _ColorItem extends StatelessWidget {
  const _ColorItem({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );
    final image = item.imageUrl?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null && image.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: AppColors.sageLight),
                errorWidget: (_, _, _) => ColoredBox(
                  color: AppColors.sageLight,
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    color: _colorFor(item.title),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.wb_sunny, color: _colorFor(item.title), size: 28),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (blocks.isNotEmpty) ...[
                const SizedBox(height: 6),
                BlogHtmlView(blocks: blocks),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _colorFor(String title) {
    switch (title.trim().toLowerCase()) {
      case 'violet':
        return const Color(0xFF7B2CBF);
      case 'blue':
        return const Color(0xFF2F80ED);
      case 'green':
        return const Color(0xFF27AE60);
      case 'yellow':
        return const Color(0xFFF2C94C);
      case 'orange':
        return const Color(0xFFF2994A);
      case 'red':
        return const Color(0xFFEB5757);
      default:
        return AppColors.brandAccent;
    }
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.sections});

  final List<ServiceSection> sections;

  @override
  Widget build(BuildContext context) {
    final urls = sections
        .map((section) => section.imageUrl?.trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (urls.length == 1) {
            return _RoundedImage(url: urls.first, height: 240);
          }
          final width = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final url in urls)
                SizedBox(
                  width: width,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 0.78,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: AppColors.sageLight),
                        errorWidget: (_, _, _) => const ColoredBox(
                          color: AppColors.sageLight,
                          child: Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FaqAccordion extends StatefulWidget {
  const _FaqAccordion({required this.section});

  final ServiceSection section;

  @override
  State<_FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<_FaqAccordion> {
  late final Set<int> _open;

  @override
  void initState() {
    super.initState();
    // Keep answers visible so API content is not hidden behind taps.
    _open = {
      for (var i = 0; i < widget.section.items.length; i++) i,
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.section.items
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.section.title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++) ...[
            _FaqTile(
              item: items[i],
              expanded: _open.contains(i),
              onToggle: () => setState(() {
                if (_open.contains(i)) {
                  _open.remove(i);
                } else {
                  _open.add(i);
                }
              }),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.expanded,
    required this.onToggle,
  });

  final ServiceSectionItem item;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandNavy,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      expanded ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.brandNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded && blocks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: BlogHtmlView(blocks: blocks),
            ),
        ],
      ),
    );
  }
}

class _ExpectSection extends StatelessWidget {
  const _ExpectSection({required this.section, required this.source});

  final ServiceSection section;
  final SourceContext source;

  @override
  Widget build(BuildContext context) {
    final items =
        section.items.where((item) => item.title.trim().isNotEmpty).toList();

    return Container(
      width: double.infinity,
      color: AppColors.brandMutedSurface,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
      child: Column(
        children: [
          Text(
            section.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          for (final item in items) ...[
            _StepCard(item: item, source: source),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.item, required this.source});

  final ServiceSectionItem item;
  final SourceContext source;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );
    final image = item.imageUrl?.trim();
    final opensAppointment =
        item.title.toLowerCase().contains('schedule');

    final card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null && image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.sageLight),
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: AppColors.sageLight,
                      child: Icon(Icons.flag_outlined),
                    ),
                  ),
                ),
              ),
            if (image != null && image.isNotEmpty) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (blocks.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    BlogHtmlView(blocks: blocks),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!opensAppointment) return card;
    return InkWell(
      onTap: () => context.push(AppRoutes.appointmentPath(source)),
      borderRadius: BorderRadius.circular(14),
      child: card,
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _AccentTitle('What Our Patients Say'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.78,
                  child: ReviewCard(
                    reviewerName: review.reviewerName,
                    reviewText: review.reviewText,
                    rating: review.rating,
                    dateLabel: _reviewDate(review),
                    avatarUrl: review.imageUrl,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _reviewDate(Review review) {
    final raw = review.dateLabel?.trim();
    if (raw == null || raw.isEmpty) return null;
    final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (dateOnly != null) {
      return DateFormat.yMMMMd().format(
        DateTime(
          int.parse(dateOnly.group(1)!),
          int.parse(dateOnly.group(2)!),
          int.parse(dateOnly.group(3)!),
        ),
      );
    }
    return raw;
  }
}

class _AccentTitle extends StatelessWidget {
  const _AccentTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 22,
          margin: const EdgeInsets.only(top: 2, right: 10),
          color: AppColors.brandAccent,
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundedImage extends StatelessWidget {
  const _RoundedImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, _) => const ColoredBox(color: AppColors.sageLight),
          errorWidget: (_, _, _) => const ColoredBox(
            color: AppColors.sageLight,
            child: Icon(Icons.image_outlined),
          ),
        ),
      ),
    );
  }
}

class _WaveDownPainter extends CustomPainter {
  const _WaveDownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.15,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveUpPainter extends CustomPainter {
  const _WaveUpPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * -0.15,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
