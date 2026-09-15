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

/// Website-matched Personalized Wellness Plans page
/// (`/personalized-wellness-plans/`). Not shared with other service screens.
class PersonalizedWellnessPlansDetailView extends StatelessWidget {
  const PersonalizedWellnessPlansDetailView({super.key, required this.service});

  final Service service;

  static const _quote =
      'LET FOOD BE THY MEDICINE, LET MEDICINE BE THY FOOD';

  SourceContext get _source => SourceContext(
        type: SourceContextType.service,
        id: service.routeId,
        name: service.name,
      );

  String get _ctaLabel {
    final label = service.ctaLabel?.trim();
    if (label == null || label.isEmpty) return 'View Wellness Plan';
    return label;
  }

  String? get _ctaUrl {
    for (final section in service.sections) {
      for (final item in section.items) {
        final url = item.linkUrl?.trim() ?? '';
        if (url.isNotEmpty &&
            item.title.toLowerCase().contains('view wellness')) {
          return url;
        }
      }
    }
    final fromIntro = service.sections
        .expand((s) => s.items)
        .map((i) => i.linkUrl?.trim() ?? '')
        .firstWhere((u) => u.startsWith('http'), orElse: () => '');
    return fromIntro.isEmpty ? null : fromIntro;
  }

  @override
  Widget build(BuildContext context) {
    final sections = service.sections;
    final intro = _firstWhere(sections, _isIntro);
    final includes =
        _firstWhere(sections, _isIncludes) ?? _fallbackIncludes();
    final popular = _firstWhere(sections, _isPopular);
    final exercise = _firstWhere(sections, _isExercise);
    final started = _firstWhere(sections, (s) => s.isGettingStarted);
    final hero = service.heroImageUrl?.trim();
    final collageUrls = <String>[
      ...sections.where(_isCollageImage).map((s) => s.imageUrl!.trim()),
    ];
    // Website shows a 3-panel strip; API sends 2 image-only sections plus
    // the Medical Weightloss image used as the third panel.
    if (collageUrls.length == 2 && popular != null) {
      for (final item in popular.items) {
        final url = item.imageUrl?.trim() ?? '';
        if (url.isNotEmpty && !collageUrls.contains(url)) {
          collageUrls.add(url);
          break;
        }
      }
    }
    final viewCta = ServiceSectionItem(
      title: _ctaLabel,
      linkUrl: _ctaUrl ?? 'https://mybodysite.com/sultana-afrooz',
      linkLabel: _ctaLabel,
    );

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(title: Text(service.name)),
      body: ListView(
        children: [
          _HeroHeadingLine(
            text: service.heroHeading ?? 'personalized wellness plans',
          ),
          _PageHeadline(
            text: service.headline ??
                intro?.title ??
                'Personalized Health & Wellness Plans With Doctor Check-Ins',
          ),
          if (hero != null && hero.isNotEmpty)
            _HeroImageWithQuote(url: hero, quote: _quote)
          else
            const _QuoteBanner(_quote),
          if (intro != null) ...[
            _IntroBody(section: intro),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: AppointmentCtaBar(
                sourceContext: _source,
                label: 'Request An Appointment',
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: AppointmentCtaBar(
                sourceContext: _source,
                label: 'Request An Appointment',
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _ExternalCtaButton(item: viewCta),
          ),
          if (collageUrls.isNotEmpty) _CollageRow(urls: collageUrls),
          if (includes != null) _IncludesSection(section: includes),
          if (popular != null)
            _PlanCardsSection(
              section: popular,
              muted: false,
            ),
          if (exercise != null)
            _PlanCardsSection(
              section: exercise,
              muted: true,
            ),
          if (started != null)
            _GettingStartedSection(section: started, source: _source),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _ExternalCtaButton(item: viewCta),
          ),
          if (service.reviews.isNotEmpty)
            _ReviewsSection(reviews: service.reviews),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  ServiceSection? _fallbackIncludes() {
    if (service.benefits.isEmpty) return null;
    return ServiceSection(
      type: 'cards',
      title: 'Our Wellness Plans Include:',
      items: service.benefits
          .map((item) => ServiceSectionItem(title: item.label))
          .toList(),
    );
  }

  bool _isIntro(ServiceSection section) {
    if (section.isGettingStarted || _isCollageImage(section)) return false;
    return section.title.toLowerCase().contains('doctor check-ins') ||
        section.type == 'text';
  }

  bool _isCollageImage(ServiceSection section) {
    final url = section.imageUrl?.trim() ?? '';
    if (url.isEmpty) return false;
    return section.title.trim().isEmpty &&
        section.content.trim().isEmpty &&
        section.items.isEmpty;
  }

  bool _isIncludes(ServiceSection section) {
    return section.title.toLowerCase().contains('include');
  }

  bool _isPopular(ServiceSection section) {
    return section.title.toLowerCase().contains('popular plans');
  }

  bool _isExercise(ServiceSection section) {
    return section.title.toLowerCase().contains('exercise') &&
        section.title.toLowerCase().contains('mindfulness');
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

class _PageHeadline extends StatelessWidget {
  const _PageHeadline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.brandNavy,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
      ),
    );
  }
}

class _QuoteBanner extends StatelessWidget {
  const _QuoteBanner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '"$text"',
        textAlign: TextAlign.center,
        style: AppTextStyles.titleMedium.copyWith(
          color: Colors.white,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          height: 1.35,
        ),
      ),
    );
  }
}

class _HeroImageWithQuote extends StatelessWidget {
  const _HeroImageWithQuote({required this.url, required this.quote});

  final String url;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, _) =>
                    const ColoredBox(color: AppColors.sageLight),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: AppColors.sageLight,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
              child: Text(
                '"$quote"',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroBody extends StatelessWidget {
  const _IntroBody({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final blocks = blogContentBlocks(
      contentHtml: section.contentHtml,
      body: section.content,
    );
    if (blocks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: DefaultTextStyle(
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.brandNavy,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
        child: BlogHtmlView(blocks: blocks),
      ),
    );
  }
}

class _CollageRow extends StatelessWidget {
  const _CollageRow({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            for (var i = 0; i < urls.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: CachedNetworkImage(
                    imageUrl: urls[i],
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.sageLight),
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: AppColors.sageLight,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccentTitle extends StatelessWidget {
  const _AccentTitle(this.text, {this.centered = false});

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

class _IncludesSection extends StatelessWidget {
  const _IncludesSection({required this.section});

  final ServiceSection section;

  @override
  Widget build(BuildContext context) {
    final labels = section.items
        .map((item) => item.title.trim())
        .where((title) => title.isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccentTitle(section.title),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 14),
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

class _PlanCardsSection extends StatelessWidget {
  const _PlanCardsSection({
    required this.section,
    required this.muted,
  });

  final ServiceSection section;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: muted ? const Color(0xFFF3F8FA) : Colors.transparent,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, muted ? 24 : 8, 16, muted ? 28 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AccentTitle(section.title, centered: true),
            const SizedBox(height: 16),
            for (final item in section.items) ...[
              _PlanCard(item: item),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.item});

  final ServiceSectionItem item;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrl?.trim();
    final blocks = blogContentBlocks(
      contentHtml: item.contentHtml,
      body: item.content,
    );
    final link = item.linkUrl?.trim() ?? '';
    final label = (item.linkLabel?.trim().isNotEmpty ?? false)
        ? item.linkLabel!.trim()
        : 'View Wellness Plan';

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.brandBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image != null && image.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.sageLight),
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: AppColors.sageLight,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
            if (link.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ExternalCtaButton(
                item: ServiceSectionItem(
                  title: label,
                  linkUrl: link,
                  linkLabel: label,
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
