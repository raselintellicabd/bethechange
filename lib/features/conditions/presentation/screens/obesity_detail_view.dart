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
import '../../domain/models/condition.dart';
import '../../domain/models/condition_section.dart';

/// Website-matched Obesity page (`/obesity/`). Not shared with other conditions.
class ObesityDetailView extends StatelessWidget {
  const ObesityDetailView({super.key, required this.condition});

  final Condition condition;

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
            heroHeading: condition.heroHeading ?? 'obesity specialist',
            headline: condition.headline ??
                'Attempting to lose weight on your own can be disheartening, '
                    'especially if you can’t see or feel any results.',
            contentHtml: condition.contentHtml,
            summary: condition.summary,
            ctaLabel: _ctaLabel,
            source: _source,
          ),
          for (final section in sections) ...[
            if (_isOverview(section)) _OverviewSection(section: section),
            if (section.isTreatDark) _TreatDarkSection(section: section),
            if (_isPlanning(section)) _PlanningAccordion(section: section),
            if (section.isGettingStarted)
              _GettingStartedSection(
                section: section,
                source: _source,
              ),
          ],
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

  bool _isOverview(ConditionSection section) {
    if (!section.isDefaultLayout) return false;
    if (section.type.trim().toLowerCase() == 'text') return false;
    return section.imageUrl?.trim().isNotEmpty == true ||
        section.items.isNotEmpty;
  }

  bool _isPlanning(ConditionSection section) {
    if (section.type.trim().toLowerCase() == 'text') return true;
    return section.isDefaultLayout &&
        (section.imageUrl == null || section.imageUrl!.trim().isEmpty) &&
        section.items.isEmpty &&
        section.title.trim().isNotEmpty;
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

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.section});

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null && image.isNotEmpty) ...[
                _RoundedImage(url: image, height: 210),
                const SizedBox(height: 18),
              ],
              _AccentTitle(section.title),
              if (before.isNotEmpty) ...[
                const SizedBox(height: 10),
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
        ),
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
    final intro = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final items =
        section.items.where((item) => item.title.trim().isNotEmpty).toList();
    final image = section.imageUrl?.trim();

    return Container(
      width: double.infinity,
      color: AppColors.brandNavy,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Text(
            section.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.25,
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
            _RoundedImage(url: image, height: 180),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 20),
            _ComponentGrid(items: items),
          ],
        ],
      ),
    );
  }
}

class _ComponentGrid extends StatelessWidget {
  const _ComponentGrid({required this.items});

  final List<ConditionSectionItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _ComponentCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.item});

  final ConditionSectionItem item;

  @override
  Widget build(BuildContext context) {
    final description = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    )
        .map((block) => switch (block) {
              BlogParagraph(:final text) => text,
              BlogHeading(:final text) => text,
              BlogBulletList(:final items) => items.join('\n'),
            })
        .where((text) => text.trim().isNotEmpty)
        .join('\n');

    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(
            _iconFor(item.title),
            color: AppColors.brandAccent,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String title) {
    final key = title.trim().toLowerCase();
    if (key.contains('dietary') || key.contains('diet')) {
      return Icons.apple;
    }
    if (key.contains('eating') || key.contains('food')) {
      return Icons.restaurant_outlined;
    }
    if (key.contains('exercise')) return Icons.fitness_center_outlined;
    if (key.contains('support')) return Icons.chat_bubble_outline;
    if (key.contains('progress') || key.contains('track')) {
      return Icons.show_chart_outlined;
    }
    if (key.contains('supplement')) return Icons.medication_outlined;
    return Icons.monitor_weight_outlined;
  }
}

class _PlanningAccordion extends StatefulWidget {
  const _PlanningAccordion({required this.section});

  final ConditionSection section;

  @override
  State<_PlanningAccordion> createState() => _PlanningAccordionState();
}

class _PlanningAccordionState extends State<_PlanningAccordion> {
  // Content must be visible without relying on a website-style collapsed default.
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: widget.section.contentHtml,
      body: widget.section.content,
      subtitle: widget.section.title,
    );

    return Container(
      width: double.infinity,
      color: AppColors.brandNavy,
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
                    Icon(
                      _expanded ? Icons.remove : Icons.add,
                      color: AppColors.brandNavy,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
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
            if (_expanded && blocks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: BlogHtmlView(blocks: blocks),
              ),
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

  final ConditionSection section;
  final SourceContext source;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final steps =
        section.items.where((item) => item.title.trim().isNotEmpty).toList();

    return Column(
      children: [
        CustomPaint(
          size: Size(MediaQuery.sizeOf(context).width, 36),
          painter: const _WaveUpPainter(AppColors.brandNavy),
        ),
        Container(
          width: double.infinity,
          color: AppColors.brandMutedSurface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.brandNavy),
                  textAlign: TextAlign.center,
                  child: BlogHtmlView(blocks: blocks),
                ),
              ],
              const SizedBox(height: 18),
              for (final step in steps) ...[
                _StepCard(
                  item: step,
                  onTap: _opensAppointment(step)
                      ? () => context.push(AppRoutes.appointmentPath(source))
                      : null,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _opensAppointment(ConditionSectionItem item) {
    final title = item.title.trim().toLowerCase();
    if (title.contains('membership')) return false;
    return title.contains('appointment') || title.contains('request');
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.item, this.onTap});

  final ConditionSectionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );
    final image = item.imageUrl?.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
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
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
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
