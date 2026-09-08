import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/doctor_profile_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/image_with_caption.dart';
import '../../../../core/widgets/review_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/models/about_content.dart';
import '../../domain/models/about_content_block.dart';
import '../../domain/models/about_section.dart';

class AboutContentView extends StatelessWidget {
  const AboutContentView({
    super.key,
    required this.section,
    required this.content,
    this.showHero = false,
  });

  final AboutSection section;
  final AboutContent content;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        showHero ? 0 : AppSpacing.md,
        showHero ? 0 : AppSpacing.md,
        showHero ? 0 : AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        if (showHero)
          AppHeroBanner(
            title: section.title,
            tag: 'About',
            height: 160,
            backgroundColor: AppColors.sage,
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            showHero ? AppSpacing.md : 0,
            showHero ? AppSpacing.md : 0,
            showHero ? AppSpacing.md : 0,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final block in section.blocks) ...[
                AboutBlockWidget(block: block),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showHero ? AppSpacing.md : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.showDoctors) ...[
                SectionHeader(
                  title: 'Meet Our Doctors',
                  subtitle: content.doctorsIntro,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (content.doctors.isEmpty)
                  const EmptyStateWidget(
                    title: 'No doctors listed',
                    message: 'Doctor profiles will appear here when available.',
                    icon: Icons.medical_information_outlined,
                  )
                else
                  for (final doctor in content.doctors) ...[
                    DoctorProfileCard(
                      name: doctor.name,
                      title: doctor.title,
                      imageUrl: doctor.imageUrl,
                      bio: doctor.bio,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                const SizedBox(height: AppSpacing.md),
              ],
              if (section.showReviews) ...[
                SectionHeader(
                  title: 'What Our Patients Say',
                  subtitle: content.reviewCount == null
                      ? content.reviewSummaryLabel
                      : '${content.reviewSummaryLabel ?? 'Reviews'} · Based on ${content.reviewCount} reviews',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (content.reviews.isEmpty)
                  const EmptyStateWidget(
                    title: 'No reviews yet',
                    message: 'Patient reviews will appear here when available.',
                    icon: Icons.rate_review_outlined,
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: content.reviews.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final review = content.reviews[index];
                        return SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.78,
                          child: ReviewCard(
                            reviewerName: review.reviewerName,
                            reviewText: review.reviewText,
                            rating: review.rating,
                            dateLabel: review.dateLabel,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AboutBlockWidget extends StatelessWidget {
  const AboutBlockWidget({super.key, required this.block});

  final AboutContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (block.type) {
      AboutBlockType.heading => Text(
          block.title ?? '',
          style: theme.textTheme.headlineSmall,
        ),
      AboutBlockType.paragraph => Text(
          block.text ?? '',
          style: theme.textTheme.bodyLarge,
        ),
      AboutBlockType.quote => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: const Border(
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${block.text ?? ''}"',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (block.caption != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '— ${block.caption}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      AboutBlockType.callout => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.title != null)
                Text(block.title!, style: theme.textTheme.titleMedium),
              if (block.title != null && block.text != null)
                const SizedBox(height: AppSpacing.xs),
              if (block.text != null)
                Text(block.text!, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      AboutBlockType.bulletList || AboutBlockType.numberedList => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.title != null) ...[
              Text(block.title!, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (var i = 0; i < block.items.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppSpacing.lg,
                    child: Text(
                      block.type == AboutBlockType.numberedList
                          ? '${i + 1}.'
                          : '•',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  Expanded(
                    child: Text(block.items[i], style: theme.textTheme.bodyLarge),
                  ),
                ],
              ),
              if (i < block.items.length - 1)
                const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      AboutBlockType.image => block.imageUrl == null
          ? const SizedBox.shrink()
          : ImageWithCaption(
              imageUrl: block.imageUrl!,
              caption: block.caption ?? block.title,
            ),
    };
  }
}

/// Non-scrolling about section body for embedding in parent scroll views.
class AboutSectionBlocks extends StatelessWidget {
  const AboutSectionBlocks({super.key, required this.section});

  final AboutSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in section.blocks) ...[
          AboutBlockWidget(block: block),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
