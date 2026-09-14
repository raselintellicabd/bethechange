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

/// Website-matched Chronic Fatigue page (`/chronic-fatigue/`). Not shared with other conditions.
class ChronicFatigueDetailView extends StatelessWidget {
  const ChronicFatigueDetailView({super.key, required this.condition});

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
    final hasTreat = sections.any((s) => s.isTreatDark);
    final quote = condition.quote?.trim() ?? '';
    final quoteBody = condition.quoteBody?.trim() ?? '';
    final quoteHtml = condition.quoteHtml?.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(title: Text(condition.name)),
      body: ListView(
        children: [
          _HeroIntro(
            heroHeading: condition.heroHeading ?? 'chronic fatigue specialist',
            headline: condition.headline ??
                'Chronic fatigue and fibromyalgia are very similar conditions '
                    'that can cause widespread pain and unrelenting tiredness.',
            contentHtml: condition.contentHtml,
            summary: condition.summary,
            ctaLabel: _ctaLabel,
            source: _source,
          ),
          for (var i = 0; i < sections.length; i++) ...[
            if (sections[i].isSymptoms)
              _SymptomsSection(
                section: sections[i],
                showWaveIntoTreat: hasTreat &&
                    !_hasSymptomsAfter(sections, i) &&
                    _nextIsTreat(sections, i),
              ),
            if (sections[i].isTreatDark)
              _TreatDarkSection(section: sections[i]),
          ],
          if (quote.isNotEmpty)
            _QuoteCtaSection(
              quote: quote,
              quoteHtml: quoteHtml.isEmpty ? null : quoteHtml,
              quoteBody: quoteBody.isEmpty ? null : quoteBody,
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

  bool _hasSymptomsAfter(List<ConditionSection> sections, int index) {
    for (var i = index + 1; i < sections.length; i++) {
      if (sections[i].isSymptoms) return true;
    }
    return false;
  }

  bool _nextIsTreat(List<ConditionSection> sections, int index) {
    for (var i = index + 1; i < sections.length; i++) {
      if (sections[i].isTreatDark) return true;
      if (sections[i].isSymptoms) return false;
    }
    return false;
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
  const _SymptomsSection({
    required this.section,
    this.showWaveIntoTreat = false,
  });

  final ConditionSection section;
  final bool showWaveIntoTreat;

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
    final imageOnRight = section.imageOnRight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!imageOnRight && image != null && image.isNotEmpty) ...[
                _RoundedImage(url: image, height: 200),
                const SizedBox(height: 16),
              ],
              _AccentTitle(section.title),
              if (before.isNotEmpty) ...[
                const SizedBox(height: 10),
                BlogHtmlView(blocks: before),
              ],
              if (imageOnRight && image != null && image.isNotEmpty) ...[
                const SizedBox(height: 14),
                _RoundedImage(url: image, height: 200),
              ],
              if (bullets.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final label in bullets) ...[
                  _TealBullet(label: label, dark: false),
                  const SizedBox(height: 10),
                ],
              ],
              if (after.isNotEmpty) ...[
                const SizedBox(height: 8),
                BlogHtmlView(blocks: after),
              ],
            ],
          ),
        ),
        if (showWaveIntoTreat)
          CustomPaint(
            size: Size(MediaQuery.sizeOf(context).width, 36),
            painter: const _WaveDownPainter(AppColors.brandNavy),
          ),
      ],
    );
  }
}

class _TreatDarkSection extends StatelessWidget {
  const _TreatDarkSection({required this.section});

  final ConditionSection section;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    // Website places treatment chips between the lead and follow-up paragraphs.
    final before = blocks.isEmpty ? const <BlogContentBlock>[] : [blocks.first];
    final after = blocks.length <= 1
        ? const <BlogContentBlock>[]
        : blocks.sublist(1);
    final treatments = section.items
        .map((item) => item.title.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    final image = section.imageUrl?.trim();

    return Container(
      width: double.infinity,
      color: AppColors.brandNavy,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
          if (image != null && image.isNotEmpty) ...[
            const SizedBox(height: 20),
            _RoundedImage(url: image, height: 220),
          ],
          if (before.isNotEmpty) ...[
            const SizedBox(height: 16),
            DefaultTextStyle(
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                height: 1.55,
              ),
              child: BlogHtmlView(blocks: before),
            ),
          ],
          if (treatments.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final label in treatments) ...[
              _TealBullet(label: label, dark: true),
              const SizedBox(height: 10),
            ],
          ],
          if (after.isNotEmpty) ...[
            const SizedBox(height: 12),
            DefaultTextStyle(
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                height: 1.55,
              ),
              child: BlogHtmlView(blocks: after),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TealBullet extends StatelessWidget {
  const _TealBullet({required this.label, required this.dark});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 7, right: 12),
          decoration: BoxDecoration(
            color: dark ? Colors.white : AppColors.brandPrimary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: dark ? Colors.white : AppColors.brandNavy,
              height: 1.4,
            ),
          ),
        ),
      ],
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
