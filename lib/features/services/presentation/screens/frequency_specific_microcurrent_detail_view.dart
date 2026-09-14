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

/// Website-matched FSM page (`/frequency-specific-microcurrent/`).
/// Not shared with other service screens.
class FrequencySpecificMicrocurrentDetailView extends StatelessWidget {
  const FrequencySpecificMicrocurrentDetailView({
    super.key,
    required this.service,
  });

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
    final extraImages = sections.where(_isImageOnly).toList();
    final address = _firstWhere(sections, (s) => s.isAddressedConcerns) ??
        _fallbackAddressSection();
    final featured = _firstWhere(sections, (s) => s.isFeaturedTherapies);
    final started = _firstWhere(sections, (s) => s.isGettingStarted);

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(title: Text(service.name)),
      body: ListView(
        children: [
          _HeroIntro(
            heroHeading:
                service.heroHeading ?? 'frequency specific microcurrent',
          ),
          if (overview != null) _OverviewSection(section: overview),
          for (final imageSection in extraImages)
            _ExtraImageSection(section: imageSection),
          if (address != null)
            _AddressSection(
              section: address,
              fallbackLabels: service.addressedConcerns
                  .map((item) => item.label)
                  .where((label) => label.trim().isNotEmpty)
                  .toList(),
              ctaLabel: _ctaLabel,
              source: _source,
            ),
          if (featured != null) _FeaturedTherapiesSection(section: featured),
          if (started != null)
            _GettingStartedSection(section: started, source: _source),
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

  ServiceSection? _fallbackAddressSection() {
    if (service.addressedConcerns.isEmpty) return null;
    return ServiceSection(
      type: 'cards',
      title: 'What Does Frequency Specific Microcurrent Address?',
      items: service.addressedConcerns
          .map((item) => ServiceSectionItem(title: item.label))
          .toList(),
    );
  }

  bool _isOverview(ServiceSection section) {
    if (section.isAddressedConcerns ||
        section.isFeaturedTherapies ||
        section.isGettingStarted ||
        _isImageOnly(section)) {
      return false;
    }
    final type = section.type.trim().toLowerCase();
    if (type == 'image_text') return true;
    final image = section.imageUrl?.trim() ?? '';
    return image.isNotEmpty &&
        (section.title.trim().isNotEmpty || section.content.trim().isNotEmpty);
  }

  bool _isImageOnly(ServiceSection section) {
    if (section.isAddressedConcerns ||
        section.isFeaturedTherapies ||
        section.isGettingStarted) {
      return false;
    }
    final image = section.imageUrl?.trim() ?? '';
    if (image.isEmpty) return false;
    return section.title.trim().isEmpty &&
        section.content.trim().isEmpty &&
        (section.contentHtml == null || section.contentHtml!.trim().isEmpty) &&
        section.items.isEmpty;
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

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({required this.heroHeading});

  final String heroHeading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: _HeroHeadingLine(text: heroHeading),
    );
  }
}

class _HeroHeadingLine extends StatelessWidget {
  const _HeroHeadingLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.brandAccent, thickness: 1),
        ),
        Padding(
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
        const Expanded(
          child: Divider(color: AppColors.brandAccent, thickness: 1),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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

class _ExtraImageSection extends StatelessWidget {
  const _ExtraImageSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final image = section.imageUrl?.trim();
    if (image == null || image.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _RoundedImage(url: image, height: 220),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.section,
    required this.fallbackLabels,
    required this.ctaLabel,
    required this.source,
  });

  final ServiceSection section;
  final List<String> fallbackLabels;
  final String ctaLabel;
  final SourceContext source;

  @override
  Widget build(BuildContext context) {
    final labels = section.items
        .map((item) => item.title.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    final effectiveLabels = labels.isNotEmpty ? labels : fallbackLabels;
    final referenceHtml = section.contentHtml?.trim();
    final referenceBody = section.content.trim();
    final links = _htmlLinks(referenceHtml ?? '');
    final blocks = blogContentBlocks(
      contentHtml: referenceHtml == null || referenceHtml.isEmpty
          ? null
          : _withoutAnchors(referenceHtml),
      body: referenceBody,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (effectiveLabels.isNotEmpty) ...[
            const SizedBox(height: 18),
            _CheckConcernGrid(labels: effectiveLabels),
          ],
          const SizedBox(height: 22),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => context.push(AppRoutes.appointmentPath(source)),
              child: Text(
                ctaLabel,
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
          if (blocks.isNotEmpty) ...[
            const SizedBox(height: 22),
            BlogHtmlView(blocks: blocks),
          ],
          for (final link in links) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                  padding: EdgeInsets.zero,
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
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CheckConcernGrid extends StatelessWidget {
  const _CheckConcernGrid({required this.labels});

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

class _FeaturedTherapiesSection extends StatelessWidget {
  const _FeaturedTherapiesSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final items = section.items
        .where((item) => (item.imageUrl?.trim().isNotEmpty ?? false))
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
                _FeaturedTherapyGrid(items: items),
              ],
            ],
          ),
        ),
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
        const gap = 12.0;
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
        : (item.linkLabel?.trim() ?? 'Learn More');

    return Semantics(
      button: slug != null,
      label: label,
      child: InkWell(
        onTap: slug == null
            ? null
            : () => context.push(AppRoutes.serviceDetailPath(slug)),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
