import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/review_card.dart';
import '../../../../features/services/presentation/widgets/service_concave_band.dart';
import '../../../about/domain/models/doctor_profile.dart';
import '../../../about/domain/models/review.dart';
import '../../domain/models/home_content.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeContentProvider);

    return Scaffold(
      backgroundColor: AppColors.brandBgLight,
      appBar: AppAppBar(
        title: const Text('Be The Change'),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push(AppRoutes.about),
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading home...'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(homeContentProvider),
        ),
        data: (content) => _HomeBody(content: content),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.content});

  final HomeContent content;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _HeroSection(hero: content.hero),
        _ApproachSection(approach: content.approach),
        _ConditionsSection(section: content.conditions),
        _TherapiesSection(section: content.therapies),
        _DoctorsSection(section: content.doctors),
        _NewsletterSection(newsletter: content.newsletter),
        if (content.reviews.isNotEmpty)
          _ReviewsSection(reviews: content.reviews),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.hero});

  final HomeHero hero;

  @override
  Widget build(BuildContext context) {
    final image = hero.imageUrl;
    return SizedBox(
      height: 360,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            CachedNetworkImage(
              imageUrl: image,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: AppColors.brandNavy),
              errorWidget: (_, _, _) =>
                  const ColoredBox(color: AppColors.brandNavy),
            )
          else
            const ColoredBox(color: AppColors.brandNavy),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66003048),
                  Color(0xCC003048),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  hero.text,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (hero.ctaLabel != null) ...[
                  const SizedBox(height: 18),
                  AppButton(
                    label: hero.ctaLabel!,
                    onPressed: () => _openSitePath(context, hero.ctaUrl),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproachSection extends StatelessWidget {
  const _ApproachSection({required this.approach});

  final HomeApproach approach;

  @override
  Widget build(BuildContext context) {
    final image = approach.imageUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (approach.eyebrow.isNotEmpty)
            Text(
              approach.eyebrow.toUpperCase(),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.brandPrimary,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            approach.headline,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: image,
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
          ],
          const SizedBox(height: 14),
          Text(
            approach.content,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.ink,
              height: 1.55,
            ),
          ),
          if (approach.buttonLabel != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: approach.buttonLabel!,
              variant: AppButtonVariant.secondary,
              onPressed: () => _openSitePath(context, approach.buttonUrl),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConditionsSection extends StatelessWidget {
  const _ConditionsSection({required this.section});

  final HomeConditionsSection section;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title.toLowerCase(),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in section.items)
                    SizedBox(
                      width: width,
                      child: _ConditionCard(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({required this.item});

  final HomeLinkCard item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openSitePath(context, item.linkUrl, fallbackSlug: item.slug),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: item.imageUrl == null
                  ? const ColoredBox(color: AppColors.sageLight)
                  : CachedNetworkImage(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
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
                  if (item.summary != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.summary!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.35,
                      ),
                    ),
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

class _TherapiesSection extends StatelessWidget {
  const _TherapiesSection({required this.section});

  final HomeTherapiesSection section;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ServiceConcaveBand(
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
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final width = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final item in section.items)
                      SizedBox(
                        width: width,
                        child: _TherapyTile(item: item),
                      ),
                  ],
                );
              },
            ),
            if (section.ctaLabel != null) ...[
              const SizedBox(height: 20),
              AppButton(
                label: section.ctaLabel!,
                onPressed: () => _openSitePath(context, section.ctaUrl),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TherapyTile extends StatelessWidget {
  const _TherapyTile({required this.item});

  final HomeLinkCard item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openSitePath(context, item.linkUrl, fallbackSlug: item.slug),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.2,
              child: item.imageUrl == null
                  ? const ColoredBox(color: Color(0x33FFFFFF))
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const ColoredBox(color: Color(0x33FFFFFF)),
                      errorWidget: (_, _, _) => const ColoredBox(
                        color: Color(0x33FFFFFF),
                        child: Icon(Icons.image_outlined, color: Colors.white70),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorsSection extends StatelessWidget {
  const _DoctorsSection({required this.section});

  final HomeDoctorsSection section;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (section.intro.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              section.intro,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (final doctor in section.items) ...[
            _DoctorCard(doctor: doctor),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final DoctorProfile doctor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(AppRoutes.doctorDetailPath(doctor.routeId)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: doctor.imageUrl == null
                      ? const ColoredBox(color: AppColors.sageLight)
                      : CachedNetworkImage(
                          imageUrl: doctor.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const ColoredBox(color: AppColors.sageLight),
                          errorWidget: (_, _, _) => const ColoredBox(
                            color: AppColors.sageLight,
                            child: Icon(Icons.person_outline),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.brandNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (doctor.title.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        doctor.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.inkMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsletterSection extends StatelessWidget {
  const _NewsletterSection({required this.newsletter});

  final HomeNewsletter newsletter;

  @override
  Widget build(BuildContext context) {
    if (newsletter.headline.isEmpty && newsletter.subtext.isEmpty) {
      return const SizedBox.shrink();
    }
    final bg = newsletter.backgroundImageUrl;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.brandNavy,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bg != null)
            CachedNetworkImage(
              imageUrl: bg,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: AppColors.brandNavy),
              errorWidget: (_, _, _) =>
                  const ColoredBox(color: AppColors.brandNavy),
            ),
          const ColoredBox(color: Color(0x99003048)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  newsletter.headline,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  newsletter.subtext,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
                ),
                if (newsletter.buttonLabel != null) ...[
                  const SizedBox(height: 14),
                  AppButton(
                    label: newsletter.buttonLabel!,
                    onPressed: () =>
                        _openSitePath(context, newsletter.buttonUrl),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'What our patients say',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final date = review.dateLabel == null
                  ? null
                  : DateTime.tryParse(review.dateLabel!);
              return SizedBox(
                width: 300,
                child: ReviewCard(
                  reviewerName: review.reviewerName,
                  reviewText: review.reviewText,
                  rating: review.rating,
                  avatarUrl: review.imageUrl,
                  dateLabel: date == null
                      ? review.dateLabel
                      : DateFormat.yMMMd().format(date),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

void _openSitePath(
  BuildContext context,
  String? path, {
  String? fallbackSlug,
}) {
  final raw = (path ?? '').trim();
  final value = raw.isEmpty ? (fallbackSlug ?? '') : raw;
  if (value.isEmpty) return;

  final uri = Uri.tryParse(value);
  final routePath = uri == null
      ? value
      : (uri.hasScheme ? uri.path : value.split('?').first);

  final normalized = routePath.startsWith('/') ? routePath : '/$routePath';
  final segments =
      normalized.split('/').where((part) => part.isNotEmpty).toList();

  if (normalized.startsWith('/faq')) {
    context.push(AppRoutes.faq);
    return;
  }
  if (normalized.startsWith('/our-process')) {
    context.push(AppRoutes.aboutSectionPath('our-process'));
    return;
  }
  if (normalized.startsWith('/about')) {
    if (segments.length >= 2) {
      context.push(AppRoutes.aboutSectionPath(segments[1]));
    } else {
      context.push(AppRoutes.about);
    }
    return;
  }
  if (normalized.startsWith('/services') || segments.isEmpty) {
    context.go(AppRoutes.exploreServices);
    return;
  }
  if (normalized.startsWith('/appointments')) {
    context.push(AppRoutes.appointmentPath(AppRoutes.clinicSourceContext));
    return;
  }

  // Condition or service detail by last slug.
  final slug = segments.last;
  final knownConditions = {
    'diabetes',
    'obesity',
    'heart-disease',
    'chronic-fatigue',
    'chronic-pain',
    'toxins',
    'concussion',
    'hormone-imbalance',
    'detoxification',
  };
  if (knownConditions.contains(slug) || slug == 'toxins') {
    final id = slug == 'detoxification' ? 'toxins' : slug;
    context.push(AppRoutes.conditionDetailPath(id));
    return;
  }
  context.push(AppRoutes.serviceDetailPath(slug));
}
