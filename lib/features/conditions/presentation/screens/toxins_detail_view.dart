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
import '../../domain/models/condition.dart';
import '../../domain/models/condition_section.dart';

/// Website-matched Toxins page (`/toxins/`). Not shared with other conditions.
class ToxinsDetailView extends StatelessWidget {
  const ToxinsDetailView({super.key, required this.condition});

  final Condition condition;

  static const _clinicPhoneDisplay = '301-970-9724';
  static const _clinicPhoneTel = 'tel:3019709724';

  SourceContext get _source => SourceContext(
        type: SourceContextType.condition,
        id: condition.routeId,
        name: condition.name,
      );

  String get _ctaLabel {
    final label = condition.ctaLabel?.trim();
    if (label == null || label.isEmpty) {
      return 'New Patient – Request An Appointment';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final sections = condition.sections;

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(title: Text(condition.name)),
      body: ListView(
        children: [
          _HeroIntro(
            heroHeading: condition.heroHeading ?? 'toxins specialist',
            headline: condition.headline ??
                'Throughout life, smoke inhalation, use of chemical products, '
                    'and even certain foods leave toxins in your body that can '
                    'influence your health and wellness.',
            contentHtml: condition.contentHtml,
            summary: condition.summary,
            ctaLabel: _ctaLabel,
            source: _source,
          ),
          for (final section in sections) ...[
            if (section.isSymptoms) _SymptomsSection(section: section),
            if (_isSpecializeCard(section))
              _SpecializeCard(section: section),
            if (section.isTreatDark) _TreatDarkSection(section: section),
            if (_isBenefitsAccordion(section))
              _BenefitsAccordion(section: section),
          ],
          _QuoteCtaSection(
            quote: condition.quote ?? 'Feel Good, Live Better!',
            quoteHtml: condition.quoteHtml,
            quoteBody: condition.quoteBody,
            phoneDisplay: _clinicPhoneDisplay,
            phoneTel: _clinicPhoneTel,
            source: _source,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppointmentCtaBar(
              sourceContext: _source,
              label: _ctaLabel,
            ),
          ),
          if (condition.reviews.isNotEmpty)
            _ReviewsSection(reviews: condition.reviews),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  bool _isSpecializeCard(ConditionSection section) {
    if (section.isSymptoms || section.isTreatDark) return false;
    final isText = section.type.trim().toLowerCase() == 'text' ||
        section.isDefaultLayout;
    return isText && section.items.isEmpty;
  }

  bool _isBenefitsAccordion(ConditionSection section) {
    if (section.isSymptoms || section.isTreatDark) return false;
    final isText = section.type.trim().toLowerCase() == 'text' ||
        section.isDefaultLayout;
    return isText && section.items.isNotEmpty;
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro({
    required this.heroHeading,
    required this.headline,
    required this.ctaLabel,
    required this.source,
    this.contentHtml,
    this.summary = '',
  });

  final String heroHeading;
  final String headline;
  final String? contentHtml;
  final String summary;
  final String ctaLabel;
  final SourceContext source;

  @override
  Widget build(BuildContext context) {
    final intro = blogContentBlocks(
      contentHtml: contentHtml,
      body: summary,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          _HeroHeadingLine(text: heroHeading),
          const SizedBox(height: 18),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (intro.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              intro
                  .map((block) => switch (block) {
                        BlogParagraph(:final text) => text,
                        BlogHeading(:final text) => text,
                        BlogBulletList(:final items) => items.join('\n'),
                      })
                  .join('\n\n'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.brandNavy,
                height: 1.55,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => context.push(AppRoutes.appointmentPath(source)),
              child: Text(
                ctaLabel,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
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

class _SymptomsSection extends StatelessWidget {
  const _SymptomsSection({required this.section});

  final ConditionSection section;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final before = <BlogContentBlock>[];
    BlogBulletList? list;
    final after = <BlogContentBlock>[];
    for (final block in blocks) {
      if (block is BlogBulletList && list == null) {
        list = block;
      } else if (list == null) {
        before.add(block);
      } else {
        after.add(block);
      }
    }
    final itemLabels = section.items
        .map((item) => item.title.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    final bullets = list?.items.isNotEmpty == true ? list!.items : itemLabels;
    final image = section.imageUrl?.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null && image.isNotEmpty) ...[
            _RoundedImage(url: image, height: 220),
            const SizedBox(height: 18),
          ],
          Text(
            section.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (before.isNotEmpty) ...[
            const SizedBox(height: 12),
            BlogHtmlView(blocks: before),
          ],
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final label in bullets) ...[
              _NavyBullet(label: label),
              const SizedBox(height: 8),
            ],
          ],
          if (after.isNotEmpty) ...[
            const SizedBox(height: 8),
            BlogHtmlView(blocks: after),
          ],
        ],
      ),
    );
  }
}

class _SpecializeCard extends StatelessWidget {
  const _SpecializeCard({required this.section});

  final ConditionSection section;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.brandNavy,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Text(
              section.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 14, top: 4),
                  child: Icon(
                    Icons.bubble_chart_outlined,
                    color: AppColors.brandPrimary,
                    size: 48,
                  ),
                ),
                Expanded(
                  child: DefaultTextStyle(
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      height: 1.55,
                    ),
                    child: blocks.isEmpty
                        ? const SizedBox.shrink()
                        : BlogHtmlView(blocks: blocks),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TreatDarkSection extends StatelessWidget {
  const _TreatDarkSection({required this.section});

  final ConditionSection section;

  @override
  Widget build(BuildContext context) {
    final intro = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final image = section.imageUrl?.trim();
    final methods =
        section.items.where((item) => item.title.trim().isNotEmpty).toList();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  section.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
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
              if (image != null && image.isNotEmpty) ...[
                const SizedBox(height: 18),
                _RoundedImage(url: image, height: 200),
              ],
              if (methods.isNotEmpty) ...[
                const SizedBox(height: 22),
                for (final method in methods) ...[
                  _MethodDetail(item: method),
                  const SizedBox(height: 18),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MethodDetail extends StatelessWidget {
  const _MethodDetail({required this.item});

  final ConditionSectionItem item;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              margin: const EdgeInsets.only(right: 10),
              color: AppColors.brandAccent,
            ),
            Expanded(
              child: Text(
                item.title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (blocks.isNotEmpty) ...[
          const SizedBox(height: 12),
          DefaultTextStyle(
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white,
              height: 1.55,
            ),
            child: BlogHtmlView(blocks: blocks),
          ),
        ],
      ],
    );
  }
}

class _BenefitsAccordion extends StatefulWidget {
  const _BenefitsAccordion({required this.section});

  final ConditionSection section;

  @override
  State<_BenefitsAccordion> createState() => _BenefitsAccordionState();
}

class _BenefitsAccordionState extends State<_BenefitsAccordion> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: widget.section.contentHtml,
      body: widget.section.content,
      subtitle: widget.section.title,
    );
    final before = <BlogContentBlock>[];
    BlogBulletList? list;
    final after = <BlogContentBlock>[];
    for (final block in blocks) {
      if (block is BlogBulletList && list == null) {
        list = block;
      } else if (list == null) {
        before.add(block);
      } else {
        after.add(block);
      }
    }
    final itemLabels = widget.section.items
        .map((item) => item.title.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    final bullets = list?.items.isNotEmpty == true ? list!.items : itemLabels;

    return Container(
      width: double.infinity,
      color: AppColors.brandNavy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: AppColors.brandNavy,
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
                        widget.section.title,
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
                    if (before.isNotEmpty) BlogHtmlView(blocks: before),
                    if (bullets.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (final label in bullets) ...[
                        _NavyBullet(label: label),
                        const SizedBox(height: 8),
                      ],
                    ],
                    if (after.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      BlogHtmlView(blocks: after),
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

class _QuoteCtaSection extends StatelessWidget {
  const _QuoteCtaSection({
    required this.quote,
    required this.phoneDisplay,
    required this.phoneTel,
    required this.source,
    this.quoteHtml,
    this.quoteBody,
  });

  final String quote;
  final String? quoteHtml;
  final String? quoteBody;
  final String phoneDisplay;
  final String phoneTel;
  final SourceContext source;

  @override
  Widget build(BuildContext context) {
    final bodyBlocks = blogContentBlocks(
      contentHtml: quoteHtml,
      body: quoteBody ?? '',
    );

    return Column(
      children: [
        CustomPaint(
          size: Size(MediaQuery.sizeOf(context).width, 36),
          painter: const _WaveUpPainter(AppColors.brandNavy),
        ),
        Container(
          width: double.infinity,
          color: AppColors.brandBgLight,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              Text(
                quote,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (bodyBlocks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bodyBlocks
                      .map((block) => switch (block) {
                            BlogParagraph(:final text) => text,
                            BlogHeading(:final text) => text,
                            BlogBulletList(:final items) => items.join('\n'),
                          })
                      .join('\n\n'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.brandNavy,
                    height: 1.55,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(phoneTel)),
                    child: Text(
                      'Call now! $phoneDisplay',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.brandNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () =>
                        context.push(AppRoutes.appointmentPath(source)),
                    child: Text(
                      'Book Online',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
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

class _NavyBullet extends StatelessWidget {
  const _NavyBullet({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 7, right: 12),
          decoration: const BoxDecoration(
            color: AppColors.brandNavy,
            shape: BoxShape.circle,
          ),
        ),
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
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
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
            child: Icon(Icons.broken_image_outlined),
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
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, size.height, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveUpPainter extends CustomPainter {
  const _WaveUpPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width / 2, 0, size.width, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
