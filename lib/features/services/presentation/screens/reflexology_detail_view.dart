import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/service_concave_band.dart';

/// Website-matched Reflexology page (`/reflexology/`).
/// Not shared with other service screens.
class ReflexologyDetailView extends StatelessWidget {
  const ReflexologyDetailView({super.key, required this.service});

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
    final overview = _firstWhere(sections, _isOverview);
    final howItWorks = _firstWhere(sections, _isHowItWorks);
    final studies = _firstWhere(sections, _isStudies);
    final whoBenefits = _firstWhere(sections, _isWhoBenefits);
    final contraindications = _firstWhere(sections, _isContraindications);
    final featured = _firstWhere(sections, (s) => s.isFeaturedTherapies);
    final started = _firstWhere(sections, (s) => s.isGettingStarted);

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(title: Text(service.name)),
      body: ListView(
        children: [
          _HeroHeadingLine(text: service.heroHeading ?? 'reflexology'),
          if (overview != null) ...[
            _OverviewSection(section: overview),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: AppointmentCtaBar(
                sourceContext: _source,
                label: _ctaLabel,
              ),
            ),
          ],
          if (howItWorks != null) _HowItWorksSection(section: howItWorks),
          if (studies != null) _ScientificStudiesSection(section: studies),
          if (whoBenefits != null) _WhoBenefitsSection(section: whoBenefits),
          if (contraindications != null)
            _ContraindicationsSection(section: contraindications),
          if (featured != null) _FeaturedTherapiesSection(section: featured),
          if (started != null)
            _GettingStartedSection(section: started, source: _source),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppointmentCtaBar(
              sourceContext: _source,
              label: _ctaLabel,
            ),
          ),
          if (service.reviews.isNotEmpty)
            _ReviewsSection(reviews: service.reviews),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  bool _isOverview(ServiceSection section) {
    if (section.isFeaturedTherapies || section.isGettingStarted) return false;
    return section.title.toLowerCase().contains('what is reflexology');
  }

  bool _isHowItWorks(ServiceSection section) {
    return section.title.toLowerCase().contains('how does reflexology');
  }

  bool _isStudies(ServiceSection section) {
    return section.title.toLowerCase().contains('scientific');
  }

  bool _isWhoBenefits(ServiceSection section) {
    return section.title.toLowerCase().contains('who benefits');
  }

  bool _isContraindications(ServiceSection section) {
    return section.title.toLowerCase().contains('contraindication');
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
                text.toLowerCase(),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null && image.isNotEmpty) ...[
            _RoundedImage(url: image, height: 220),
            const SizedBox(height: 18),
          ],
          _AccentTitle(section.title),
          if (blocks.isNotEmpty) ...[
            const SizedBox(height: 12),
            BlogHtmlView(blocks: blocks),
          ],
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final intro = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
    );
    final items = section.items
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentTitle(section.title),
          if (intro.isNotEmpty) ...[
            const SizedBox(height: 12),
            BlogHtmlView(blocks: intro),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final item in items) ...[
              _TheoryParagraph(item: item),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _TheoryParagraph extends StatelessWidget {
  const _TheoryParagraph({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final body = (item.contentHtml?.trim().isNotEmpty ?? false)
        ? item.contentHtml!
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&amp;', '&')
            .trim()
        : item.content.trim();

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: item.title.trim(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: ' – $body',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScientificStudiesSection extends StatelessWidget {
  const _ScientificStudiesSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final paragraphs = _htmlParagraphs(section.contentHtml ?? section.content);
    final checklist = section.items
        .map((item) => item.title.trim())
        .where((title) => title.isNotEmpty)
        .toList();

    // Website order: intro, "So far…", checklist, then study write-ups.
    String? lead;
    String? evidenceLead;
    final studies = <String>[];
    for (final paragraph in paragraphs) {
      final lower = paragraph.toLowerCase();
      if (lower.contains('so far') && lower.contains('evidence')) {
        evidenceLead = paragraph;
      } else if (lead == null) {
        lead = paragraph;
      } else {
        studies.add(paragraph);
      }
    }

    return ColoredBox(
      color: const Color(0xFFF3F8FA),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccentTitle(section.title),
            if (lead != null) ...[
              const SizedBox(height: 12),
              Text(
                lead,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.brandNavy,
                  height: 1.55,
                ),
              ),
            ],
            if (evidenceLead != null) ...[
              const SizedBox(height: 12),
              Text(
                evidenceLead,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.brandNavy,
                  height: 1.55,
                ),
              ),
            ],
            if (checklist.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final label in checklist) ...[
                _CheckRow(label: label),
                const SizedBox(height: 8),
              ],
            ],
            for (final study in studies) ...[
              const SizedBox(height: 12),
              Text(
                study,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.brandNavy,
                  height: 1.55,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WhoBenefitsSection extends StatelessWidget {
  const _WhoBenefitsSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final quote = (section.contentHtml?.trim().isNotEmpty ?? false)
        ? section.contentHtml!
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&amp;', '&')
            .trim()
        : section.content.trim();
    final labels = section.items
        .map((item) => item.title.trim())
        .where((title) => title.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentTitle(section.title),
          if (quote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              quote,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.brandNavy,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final label in labels) ...[
              _CheckRow(label: label),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _ContraindicationsSection extends StatelessWidget {
  const _ContraindicationsSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final links = _htmlLinks(section.contentHtml ?? '');

    return ColoredBox(
      color: const Color(0xFFF3F8FA),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in section.items.where(
              (entry) => entry.title.trim().isNotEmpty,
            )) ...[
              Text(
                '${item.title.trim()}:',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ..._listLines(item).map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•  ',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.brandNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.brandNavy,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (links.isNotEmpty) ...[
              Text(
                'Resources:',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              for (final link in links) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(link.href),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(
                      link.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brandPrimary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<String> _listLines(ServiceSectionItem item) {
    final html = item.contentHtml?.trim() ?? '';
    if (html.isNotEmpty) {
      final fromLi = RegExp(r'<li>(.*?)</li>', caseSensitive: false, dotAll: true)
          .allMatches(html)
          .map((match) => (match.group(1) ?? '')
              .replaceAll(RegExp(r'<[^>]+>'), '')
              .replaceAll('&amp;', '&')
              .trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (fromLi.isNotEmpty) return fromLi;
    }
    return item.lines;
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle,
            size: 20,
            color: AppColors.brandAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.brandNavy,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedTherapiesSection extends StatelessWidget {
  const _FeaturedTherapiesSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final items = section.items
        .where((item) => (item.imageUrl?.trim().isNotEmpty ?? false))
        .toList();

    return ServiceConcaveBand(
      child: Column(
        children: [
              Text(
                section.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 12.0;
                    final width = (constraints.maxWidth - gap) / 2;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: width,
                            child: _FeaturedTile(item: item),
                          ),
                      ],
                    );
                  },
                ),
              ],
        ],
      ),
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final slug = item.linkSlug;
    return Semantics(
      button: slug != null,
      label: item.title,
      child: InkWell(
        onTap: slug == null
            ? null
            : () => context.push(AppRoutes.serviceDetailPath(slug)),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.05,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
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
            if (item.title.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.title.trim(),
                textAlign: TextAlign.center,
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GettingStartedSection extends StatelessWidget {
  const _GettingStartedSection({
    required this.section,
    required this.source,
  });

  final ServiceSection section;
  final SourceContext source;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );

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
          if (blocks.isNotEmpty) ...[
            const SizedBox(height: 8),
            DefaultTextStyle(
              style:
                  AppTextStyles.bodyLarge.copyWith(color: AppColors.brandNavy),
              textAlign: TextAlign.center,
              child: BlogHtmlView(blocks: blocks),
            ),
          ],
          const SizedBox(height: 18),
          for (final step
              in section.items.where((item) => item.title.isNotEmpty)) ...[
            _StepCard(item: step, source: source),
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
        item.title.toLowerCase().contains('request an appointment');

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
      onTap: () => context.push(AppRoutes.bookingEntryPath(source)),
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

List<String> _htmlParagraphs(String raw) {
  final html = raw.trim();
  if (html.contains('<p')) {
    return RegExp(r'<p>(.*?)</p>', caseSensitive: false, dotAll: true)
        .allMatches(html)
        .map((match) => (match.group(1) ?? '')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&amp;', '&')
            .trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
