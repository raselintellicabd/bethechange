import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/review_card.dart';
import '../../../about/domain/models/review.dart';
import '../../../blog/domain/models/blog_html.dart';
import '../../../blog/presentation/widgets/blog_html_view.dart';
import '../../domain/models/service.dart';

/// Website-matched Wellness Classes page (`/wellness-classes/`).
/// Not shared with other service screens.
class WellnessClassesDetailView extends StatelessWidget {
  const WellnessClassesDetailView({super.key, required this.service});

  final Service service;

  static const _intro =
      'Naturopathic and integrative medicine services at Be The Change '
      'Wellness Center can help you to take a deep dive into the foundations '
      'of health through a holistic lens. Classes include weight loss, '
      'pediatric nutrition, tooth health, blood sugar balance, and more.';

  @override
  Widget build(BuildContext context) {
    final sections = service.sections;
    final weightLoss = _firstWhere(sections, _isWeightLoss);
    final pediatric = _firstWhere(sections, _isPediatric);
    final comingSoon = _firstWhere(sections, _isComingSoon);
    final books = _firstWhere(sections, _isBooks);
    final bottomCta = _signupItems(weightLoss)
        .where((item) => item.title.toLowerCase().contains('in-person'))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(title: Text(service.name)),
      body: ListView(
        children: [
          _HeroHeadingLine(text: service.heroHeading ?? 'wellness classes'),
          const _IntroCopy(_intro),
          if (weightLoss != null) _ProgramSection(section: weightLoss),
          if (pediatric != null)
            _ProgramSection(
              section: pediatric,
              background: const Color(0xFFEEF4E8),
            ),
          if (comingSoon != null) _ComingSoonSection(section: comingSoon),
          if (books != null) _BooksSection(section: books),
          if (service.reviews.isNotEmpty)
            _ReviewsSection(reviews: service.reviews),
          if (bottomCta.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: _ExternalCtaButton(item: bottomCta.first),
            )
          else
            const SizedBox(height: 28),
        ],
      ),
    );
  }

  bool _isWeightLoss(ServiceSection section) {
    return section.title.toLowerCase().contains('weight loss');
  }

  bool _isPediatric(ServiceSection section) {
    return section.title.toLowerCase().contains('pediatric');
  }

  bool _isComingSoon(ServiceSection section) {
    return section.title.toLowerCase().contains('coming soon');
  }

  bool _isBooks(ServiceSection section) {
    return section.title.toLowerCase().contains('recommended books');
  }

  List<ServiceSectionItem> _signupItems(ServiceSection? section) {
    if (section == null) return const [];
    return section.items
        .where((item) => (item.linkUrl?.trim().isNotEmpty ?? false))
        .toList();
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
  const _IntroCopy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.brandNavy,
          height: 1.5,
        ),
      ),
    );
  }
}

class _AccentTitle extends StatelessWidget {
  const _AccentTitle(
    this.text, {
    this.centered = false,
  });

  final String text;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    if (centered) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.brandNavy,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      );
    }

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

class _ProgramSection extends StatelessWidget {
  const _ProgramSection({
    required this.section,
    this.background = Colors.transparent,
  });

  final ServiceSection section;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
      subtitle: section.title,
    );
    final image = section.imageUrl?.trim();
    final checklist = section.items
        .where(
          (item) =>
              item.title.trim().isNotEmpty &&
              (item.linkUrl == null || item.linkUrl!.trim().isEmpty),
        )
        .toList();
    final ctas = section.items
        .where((item) => (item.linkUrl?.trim().isNotEmpty ?? false))
        .toList();

    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccentTitle(section.title, centered: true),
            if (image != null && image.isNotEmpty) ...[
              const SizedBox(height: 16),
              _RoundedImage(url: image, height: 200),
            ],
            if (blocks.isNotEmpty) ...[
              const SizedBox(height: 16),
              BlogHtmlView(blocks: blocks),
            ],
            if (checklist.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final item in checklist) ...[
                _CheckRow(label: item.title.trim()),
                const SizedBox(height: 10),
              ],
            ],
            if (ctas.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final item in ctas) ...[
                _ExternalCtaButton(item: item),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ComingSoonSection extends StatelessWidget {
  const _ComingSoonSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final intro = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
    );

    return ColoredBox(
      color: const Color(0xFFF3F8FA),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccentTitle(section.title, centered: true),
            if (intro.isNotEmpty) ...[
              const SizedBox(height: 12),
              BlogHtmlView(blocks: intro),
            ],
            if (section.items.isNotEmpty) ...[
              const SizedBox(height: 18),
              for (final item in section.items) ...[
                _ComingSoonCard(item: item),
                const SizedBox(height: 14),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrl?.trim();
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null && image.isNotEmpty) ...[
              _RoundedImage(url: image, height: 160),
              const SizedBox(height: 12),
            ],
            Text(
              item.title.trim(),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (blocks.isNotEmpty) ...[
              const SizedBox(height: 8),
              BlogHtmlView(blocks: blocks),
            ],
          ],
        ),
      ),
    );
  }
}

class _BooksSection extends StatelessWidget {
  const _BooksSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final intro = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
      child: Column(
        children: [
          Text(
            section.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (intro.isNotEmpty) ...[
            const SizedBox(height: 10),
            DefaultTextStyle(
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.brandText,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
              child: BlogHtmlView(blocks: intro),
            ),
          ],
          if (section.items.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (final item in section.items) ...[
              _BookRow(item: item),
              const SizedBox(height: 18),
            ],
          ],
        ],
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrl?.trim();
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null && image.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 96,
              height: 128,
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: AppColors.sageLight),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: AppColors.sageLight,
                  child: Icon(Icons.menu_book_outlined),
                ),
              ),
            ),
          ),
        if (image != null && image.isNotEmpty) const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title.trim(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (blocks.isNotEmpty) ...[
                const SizedBox(height: 8),
                BlogHtmlView(blocks: blocks),
              ],
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
    return ColoredBox(
      color: const Color(0xFFF3F8FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'What Our Patients Say',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.brandNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              scrollDirection: Axis.horizontal,
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.82,
                  child: ReviewCard(
                    reviewerName: review.reviewerName,
                    reviewText: review.reviewText,
                    rating: review.rating,
                    dateLabel: _formatDate(review.dateLabel),
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

  String? _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat.yMMMd().format(parsed);
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
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 2),
          decoration: const BoxDecoration(
            color: AppColors.brandAccent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
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

class _ExternalCtaButton extends StatelessWidget {
  const _ExternalCtaButton({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final label = (item.linkLabel?.trim().isNotEmpty ?? false)
        ? item.linkLabel!.trim()
        : item.title.trim();
    final url = item.linkUrl?.trim() ?? '';

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: url.isEmpty
            ? null
            : () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
      borderRadius: BorderRadius.circular(14),
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
