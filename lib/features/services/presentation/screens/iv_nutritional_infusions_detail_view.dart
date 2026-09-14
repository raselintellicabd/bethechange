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

/// Website-matched IV Nutritional Infusions page (`/iv-nutritional-infusions/`).
/// Not shared with other service screens.
class IvNutritionalInfusionsDetailView extends StatelessWidget {
  const IvNutritionalInfusionsDetailView({super.key, required this.service});

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
    final therapeutic = _firstWhere(sections, _isTherapeutic);
    final nutritional = _firstWhere(sections, _isNutritional);
    final featured = _firstWhere(sections, (s) => s.isFeaturedTherapies);
    final started = _firstWhere(sections, (s) => s.isGettingStarted);

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(title: Text(service.name)),
      body: ListView(
        children: [
          _HeroHeadingLine(
            text: service.heroHeading ?? 'iv nutritional infusions',
          ),
          _IntroCopy(service: service),
          if (therapeutic != null) ...[
            _IvCardsSection(
              section: therapeutic,
              background: AppColors.brandMutedSurface,
              style: _IvCardStyle.therapeutic,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: AppointmentCtaBar(
                sourceContext: _source,
                label: _ctaLabel,
              ),
            ),
          ],
          if (nutritional != null)
            _IvCardsSection(
              section: nutritional,
              background: const Color(0xFFF3F8FA),
              style: _IvCardStyle.nutritional,
            ),
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

  bool _isTherapeutic(ServiceSection section) {
    if (section.isFeaturedTherapies || section.isGettingStarted) return false;
    return section.title.toLowerCase().contains('therapeutic');
  }

  bool _isNutritional(ServiceSection section) {
    if (section.isFeaturedTherapies || section.isGettingStarted) return false;
    final title = section.title.toLowerCase();
    return title.contains('nutritional') && !title.contains('therapeutic');
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

class _IntroCopy extends StatelessWidget {
  const _IntroCopy({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final html = service.contentHtml?.trim();
    final body = (html != null && html.isNotEmpty)
        ? html
        : (service.summary.trim().isNotEmpty
            ? service.summary
            : service.articleBody);
    final blocks = blogContentBlocks(
      contentHtml: html,
      body: body,
    );
    if (blocks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: DefaultTextStyle(
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.brandNavy,
          height: 1.55,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
        child: BlogHtmlView(blocks: blocks),
      ),
    );
  }
}

enum _IvCardStyle { therapeutic, nutritional }

class _IvCardsSection extends StatelessWidget {
  const _IvCardsSection({
    required this.section,
    required this.background,
    required this.style,
  });

  final ServiceSection section;
  final Color background;
  final _IvCardStyle style;

  @override
  Widget build(BuildContext context) {
    final items = section.items
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        child: Column(
          children: [
            Text(
              section.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 20),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                _IvProductCard(item: items[i], style: style),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _IvProductCard extends StatelessWidget {
  const _IvProductCard({
    required this.item,
    required this.style,
  });

  final ServiceSectionItem item;
  final _IvCardStyle style;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrl?.trim();
    final parsed = _parseIvCard(item);

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppColors.brandNavy.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null && image.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.05,
                  child: CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.contain,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.sageLight),
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: AppColors.sageLight,
                      child: Icon(Icons.water_drop_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              item.title.trim().toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.35,
                height: 1.25,
              ),
            ),
            if (style == _IvCardStyle.nutritional &&
                parsed.blurb.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                parsed.blurb,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.brandPrimary,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (style == _IvCardStyle.nutritional &&
                parsed.includes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                parsed.includes,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.brandNavy,
                  height: 1.45,
                ),
              ),
            ],
            if (style == _IvCardStyle.nutritional &&
                parsed.price.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                parsed.price,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (style == _IvCardStyle.therapeutic &&
                parsed.bodyBlocks.isNotEmpty) ...[
              const SizedBox(height: 10),
              DefaultTextStyle(
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.brandNavy,
                  height: 1.5,
                ),
                child: BlogHtmlView(blocks: parsed.bodyBlocks),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParsedIvCard {
  const _ParsedIvCard({
    this.blurb = '',
    this.includes = '',
    this.price = '',
    this.bodyBlocks = const [],
  });

  final String blurb;
  final String includes;
  final String price;
  final List<BlogContentBlock> bodyBlocks;
}

_ParsedIvCard _parseIvCard(ServiceSectionItem item) {
  final lines = item.lines;
  String price = '';
  String includes = '';
  final blurbLines = <String>[];

  for (final line in lines) {
    final trimmed = line.trim();
    if (RegExp(r'^\$\d+').hasMatch(trimmed)) {
      price = trimmed;
    } else if (trimmed.toLowerCase().startsWith('includes')) {
      includes = trimmed;
    } else {
      blurbLines.add(trimmed);
    }
  }

  if (price.isEmpty || includes.isEmpty) {
    final html = item.contentHtml?.trim() ?? '';
    if (html.isNotEmpty) {
      final paragraphs = RegExp(r'<p>(.*?)</p>', caseSensitive: false, dotAll: true)
          .allMatches(html)
          .map((m) => (m.group(1) ?? '')
              .replaceAll(RegExp(r'<[^>]+>'), '')
              .replaceAll('&amp;', '&')
              .trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (paragraphs.isNotEmpty && blurbLines.isEmpty) {
        for (final p in paragraphs) {
          if (RegExp(r'^\$\d+').hasMatch(p)) {
            price = p;
          } else if (p.toLowerCase().startsWith('includes')) {
            includes = p;
          } else if (blurbLines.isEmpty) {
            blurbLines.add(p);
          }
        }
      }
    }
  }

  return _ParsedIvCard(
    blurb: blurbLines.join(' ').trim(),
    includes: includes,
    price: price,
    bodyBlocks: blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    ),
  );
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
        ),
      ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
                    'What Our Patients Say',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
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
