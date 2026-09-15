import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/external_link_handler.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/review_card.dart';
import '../../domain/models/about_page.dart';
import '../../domain/models/doctor_profile.dart';
import '../../domain/models/review.dart';
import '../providers/about_providers.dart';

class AboutPageScreen extends ConsumerWidget {
  const AboutPageScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(aboutPageProvider(slug));

    return pageAsync.when(
      loading: () => Scaffold(
        appBar: AppAppBar.text('About'),
        body: const LoadingIndicator(message: 'Loading…'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppAppBar.text('About'),
        body: ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(aboutPageProvider(slug)),
        ),
      ),
      data: (page) => Scaffold(
        backgroundColor: AppColors.brandBgLight,
        appBar: AppAppBar(
          title: Text(
            page.heroHeading.isNotEmpty ? page.heroHeading : page.title,
          ),
        ),
        body: AboutPageView(page: page),
      ),
    );
  }
}

class AboutPageView extends ConsumerWidget {
  const AboutPageView({super.key, required this.page});

  final AboutPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBodyContent = page.content.isNotEmpty && !page.isProcess;

    return ListView(
      children: [
        _HeroBanner(
          title: page.heroHeading.isNotEmpty ? page.heroHeading : page.title,
          subtitle: page.subtitle,
          // Process page uses step item images; skip the redundant hero photo.
          imageUrl: page.isProcess ? null : page.imageUrl,
        ),
        if (page.sectionTitle != null ||
            showBodyContent ||
            page.quote != null ||
            page.videoEmbedUrl != null ||
            page.principles != null ||
            page.values.isNotEmpty ||
            page.resources.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (page.sectionTitle != null) ...[
                  Text(
                    page.sectionTitle!,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (showBodyContent)
                  Text(
                    _bodyWithoutRepeatedTitle(page),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.ink,
                      height: 1.55,
                    ),
                  ),
                if (page.quote != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.sageLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page.quote!,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.brandNavy,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                        if (page.quoteAttribution != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            page.quoteAttribution!,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (page.videoEmbedUrl != null) ...[
                  const SizedBox(height: 20),
                  _VideoCard(embedUrl: page.videoEmbedUrl!),
                ],
                if (page.principles != null) ...[
                  const SizedBox(height: 24),
                  _PrinciplesBlock(principles: page.principles!),
                ],
                if (page.values.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  for (final value in page.values) ...[
                    _ValueBlock(value: value),
                    const SizedBox(height: 16),
                  ],
                ],
                if (page.resources.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  if (page.resourcesIntro != null)
                    Text(
                      page.resourcesIntro!,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                    ),
                  const SizedBox(height: 10),
                  for (final resource in page.resources)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => ref
                            .read(externalLinkHandlerProvider)
                            .openExternal(resource.url),
                        child: Text(
                          resource.label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.brandPrimary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        if (page.steps.isNotEmpty)
          for (final step in page.steps) _ProcessStepBlock(step: step),
        if (page.cta != null) _CtaBlock(cta: page.cta!),
        if (page.doctors != null && page.doctors!.items.isNotEmpty)
          _DoctorsBlock(block: page.doctors!),
        if (page.reviews.isNotEmpty) _ReviewsBlock(reviews: page.reviews),
        const SizedBox(height: 28),
      ],
    );
  }

  static String _bodyWithoutRepeatedTitle(AboutPage page) {
    var body = page.content.trim();
    final title = page.sectionTitle?.trim();
    if (title != null &&
        title.isNotEmpty &&
        body.toLowerCase().startsWith(title.toLowerCase())) {
      body = body.substring(title.length).trim();
      if (body.startsWith('\n')) body = body.trimLeft();
    }
    return body;
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    this.subtitle,
    this.imageUrl,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: subtitle == null ? 180 : 210,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: AppColors.brandNavy),
              errorWidget: (_, _, _) =>
                  const ColoredBox(color: AppColors.brandNavy),
            )
          else
            const ColoredBox(color: AppColors.brandNavy),
          const ColoredBox(color: Color(0x99003048)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.4,
                    ),
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

class _VideoCard extends ConsumerWidget {
  const _VideoCard({required this.embedUrl});

  final String embedUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchUrl = embedUrl
        .replaceFirst('/embed/', '/watch?v=')
        .replaceFirst('youtube.com/embed/', 'youtube.com/watch?v=');

    return Material(
      color: AppColors.brandNavy,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            ref.read(externalLinkHandlerProvider).openExternal(watchUrl),
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.white, size: 56),
                const SizedBox(height: 8),
                Text(
                  'Watch video',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrinciplesBlock extends StatelessWidget {
  const _PrinciplesBlock({required this.principles});

  final AboutPrinciples principles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          principles.title,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (principles.imageUrl != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: principles.imageUrl!,
              fit: BoxFit.contain,
              placeholder: (_, _) =>
                  const ColoredBox(color: AppColors.sageLight),
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < principles.items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    principles.items[i],
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.value});

  final AboutValue value;

  @override
  Widget build(BuildContext context) {
    final lines = value.bulletLines;
    final isList = value.slug == 'our-core-values' || lines.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (value.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: value.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: AppColors.sageLight),
                errorWidget: (_, _, _) =>
                    const ColoredBox(color: AppColors.sageLight),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          value.title,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        if (isList && value.slug == 'our-core-values')
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: AppColors.brandPrimary)),
                  Expanded(
                    child: Text(
                      line,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            )
        else
          Text(
            value.content,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
      ],
    );
  }
}

class _ProcessStepBlock extends StatelessWidget {
  const _ProcessStepBlock({required this.step});

  final AboutProcessStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: GoogleFonts.workSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.brandNavy,
              letterSpacing: 0.3,
            ),
          ),
          if (step.tagline != null) ...[
            const SizedBox(height: 4),
            Text(
              step.tagline!,
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.brandPrimary,
              ),
            ),
          ],
          if (step.summary != null) ...[
            const SizedBox(height: 10),
            Text(
              step.summary!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.inkMuted,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (step.layout == 'split' && step.items.isNotEmpty)
            _SplitItem(item: step.items.first)
          else
            Column(
              children: [
                for (var i = 0; i < step.items.length; i++) ...[
                  _ProcessItemCard(item: step.items[i]),
                  if (i < step.items.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _SplitItem extends StatelessWidget {
  const _SplitItem({required this.item});

  final AboutProcessItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: AppColors.sageLight),
                errorWidget: (_, _, _) =>
                    const ColoredBox(color: AppColors.sageLight),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          item.displayTitle,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.brandNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (item.content != null) ...[
          const SizedBox(height: 8),
          Text(
            item.content!,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProcessItemCard extends StatelessWidget {
  const _ProcessItemCard({required this.item});

  final AboutProcessItem item;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayTitle,
                    style: GoogleFonts.workSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: AppColors.brandNavy,
                    ),
                  ),
                  if (item.content != null && item.content!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.content!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.inkMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.imageUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.sageLight),
                    errorWidget: (_, _, _) =>
                        const ColoredBox(color: AppColors.sageLight),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (item.linkUrl == null) return child;
    return InkWell(
      onTap: () => _openInternalPath(context, item.linkUrl!),
      child: child,
    );
  }
}

class _CtaBlock extends StatelessWidget {
  const _CtaBlock({required this.cta});

  final AboutCta cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cta.headline,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cta.subtext,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (cta.phone != null)
            AppButton(
              label: cta.phoneLabel ?? 'Call now!',
              onPressed: () => launchUrl(Uri.parse('tel:${cta.phone}')),
            ),
          if (cta.bookLabel != null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: cta.bookLabel!,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                if (cta.bookUrl != null) {
                  _openInternalPath(context, cta.bookUrl!);
                } else {
                  context.push(
                    AppRoutes.appointmentPath(AppRoutes.clinicSourceContext),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DoctorsBlock extends StatelessWidget {
  const _DoctorsBlock({required this.block});

  final AboutDoctorsBlock block;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (block.intro.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              block.intro,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.inkMuted,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 14),
          for (final doctor in block.items) ...[
            _DoctorRow(doctor: doctor),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _DoctorRow extends StatelessWidget {
  const _DoctorRow({required this.doctor});

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
                  width: 72,
                  height: 72,
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
                    if (doctor.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        doctor.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.inkMuted,
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

class _ReviewsBlock extends StatelessWidget {
  const _ReviewsBlock({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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

void _openInternalPath(BuildContext context, String path) {
  final normalized = path.startsWith('/') ? path : '/$path';
  final segments =
      normalized.split('/').where((part) => part.isNotEmpty).toList();

  if (normalized.startsWith('/appointments') ||
      normalized.startsWith('/appointment')) {
    context.push(AppRoutes.appointmentPath(AppRoutes.clinicSourceContext));
    return;
  }
  if (normalized.startsWith('/services') || segments.isEmpty) {
    context.go(AppRoutes.exploreServices);
    return;
  }
  if (segments.isNotEmpty) {
    context.push(AppRoutes.serviceDetailPath(segments.last));
  }
}
