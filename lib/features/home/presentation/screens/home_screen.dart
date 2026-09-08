import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/review_card.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../features/about/domain/models/about_content.dart';
import '../../../../features/about/domain/models/doctor_profile.dart';
import '../../../../features/about/presentation/providers/about_providers.dart';
import '../../../../features/about/presentation/widgets/about_content_view.dart';
import '../../domain/models/home_content.dart';
import '../providers/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _aboutSegment = 0;

  @override
  Widget build(BuildContext context) {
    final aboutAsync = ref.watch(aboutContentProvider);
    final homeAsync = ref.watch(homeContentProvider);

    return Scaffold(
      appBar: AppAppBar.text('Be The Change'),
      body: aboutAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading…'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () {
            ref.invalidate(aboutContentProvider);
            ref.invalidate(homeContentProvider);
          },
        ),
        data: (content) {
          return homeAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading…'),
            error: (error, _) => ErrorStateWidget(
              message: error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.invalidate(homeContentProvider),
            ),
            data: (home) => _HomeBody(
              content: content,
              home: home,
              aboutSegment: _aboutSegment,
              onAboutSegmentChanged: (index) {
                setState(() => _aboutSegment = index);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.content,
    required this.home,
    required this.aboutSegment,
    required this.onAboutSegmentChanged,
  });

  final AboutContent content;
  final HomeContent home;
  final int aboutSegment;
  final ValueChanged<int> onAboutSegmentChanged;

  @override
  Widget build(BuildContext context) {
    final sections = content.sections;
    final safeIndex = sections.isEmpty
        ? 0
        : aboutSegment.clamp(0, sections.length - 1);
    final section = sections.isEmpty ? null : sections[safeIndex];

    return ListView(
      children: [
        AppHeroBanner(
          tag: home.heroTag,
          title: home.heroTitle,
          height: 190,
        ),
        if (sections.isNotEmpty) ...[
          SegmentControl(
            labels: [
              for (final s in sections)
                home.segmentLabel(s.id, s.title),
            ],
            selectedIndex: safeIndex,
            onChanged: onAboutSegmentChanged,
          ),
          if (section != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AboutSectionBlocks(section: section),
            ),
        ],
        if (content.doctors.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: SectionTitle('Meet our doctors'),
          ),
          if (content.doctorsIntro != null &&
              content.doctorsIntro!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                content.doctorsIntro!,
                style: AppTextStyles.bodySmall,
              ),
            ),
          _DoctorsRow(doctors: content.doctors),
        ],
        if (content.reviews.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: SectionTitle('What our patients say'),
          ),
          if (content.reviewSummaryLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                content.reviewCount == null
                    ? content.reviewSummaryLabel!
                    : '${content.reviewSummaryLabel} · Based on ${content.reviewCount} reviews',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: content.reviews.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
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
          ),
        ] else
          const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _DoctorsRow extends StatelessWidget {
  const _DoctorsRow({required this.doctors});

  final List<DoctorProfile> doctors;

  static const double _cardHeight = 210;
  static const double _cardWidth = 160;

  @override
  Widget build(BuildContext context) {
    if (doctors.length <= 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: _cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < doctors.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _DoctorTile(doctor: doctors[i])),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: _cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: doctors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return SizedBox(
            width: _cardWidth,
            child: _DoctorTile(doctor: doctors[index]),
          );
        },
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.doctor});

  final DoctorProfile doctor;

  String get _initials {
    final parts = doctor.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = doctor.imageUrl;

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.doctorDetailPath(doctor.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.sageLight,
                foregroundColor: AppColors.brandPrimary,
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(
                        _initials,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.brandPrimary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                doctor.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  doctor.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
