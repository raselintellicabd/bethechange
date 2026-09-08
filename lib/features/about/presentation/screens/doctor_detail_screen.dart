import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/review_card.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../domain/models/doctor_profile.dart';
import '../../domain/models/review.dart';
import '../providers/about_providers.dart';

class DoctorDetailScreen extends ConsumerWidget {
  const DoctorDetailScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return aboutAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Doctor')),
        body: const LoadingIndicator(message: 'Loading…'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Doctor')),
        body: ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(aboutContentProvider),
        ),
      ),
      data: (content) {
        final doctor = content.doctorById(doctorId);
        if (doctor == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Doctor')),
            body: const ErrorStateWidget(
              title: 'Not found',
              message: 'That doctor profile could not be found.',
            ),
          );
        }

        return _DoctorDetailBody(
          doctor: doctor,
          reviewSummaryLabel: content.reviewSummaryLabel,
          reviewCount: content.reviewCount,
          reviews: content.reviews,
        );
      },
    );
  }
}

class _DoctorDetailBody extends StatelessWidget {
  const _DoctorDetailBody({
    required this.doctor,
    required this.reviews,
    this.reviewSummaryLabel,
    this.reviewCount,
  });

  final DoctorProfile doctor;
  final List<Review> reviews;
  final String? reviewSummaryLabel;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final imageUrl = doctor.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(doctor.name),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: AppColors.sageLight,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: AppColors.sageLight,
                  child: Center(
                    child: Icon(Icons.person, size: 64, color: AppColors.sage),
                  ),
                ),
              ),
            )
          else
            const AppHeroBanner(
              title: '',
              height: 160,
              backgroundColor: AppColors.sage,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: AppTextStyles.headlineLarge),
                const SizedBox(height: 6),
                Text(
                  doctor.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  doctor.aboutHeading ?? 'About',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 10),
                for (final paragraph in doctor.detailParagraphs) ...[
                  Text(paragraph, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
          if (reviews.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SectionTitle('What our patients say'),
            ),
            if (reviewSummaryLabel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  reviewCount == null
                      ? reviewSummaryLabel!
                      : '$reviewSummaryLabel · Based on $reviewCount reviews',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                      dateLabel: review.dateLabel,
                    ),
                  );
                },
              ),
            ),
          ] else
            const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
