import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/review_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/membership_catalog.dart';
import '../providers/membership_providers.dart';

/// Membership packages from `GET /api/v1/memberships/`.
class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(membershipCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar.text('Membership'),
      body: catalogAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading memberships…'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(membershipCatalogProvider),
        ),
        data: (catalog) {
          if (catalog.plans.isEmpty) {
            return const ErrorStateWidget(
              title: 'No memberships',
              message: 'Membership packages are unavailable.',
            );
          }
          return _MembershipBody(catalog: catalog);
        },
      ),
    );
  }
}

class _MembershipBody extends ConsumerWidget {
  const _MembershipBody({required this.catalog});

  final MembershipCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        _PageHeader(title: catalog.title, content: catalog.content),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < catalog.plans.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          _PlanCard(
            plan: catalog.plans[i],
            onJoin: () => _openJoin(context, ref, catalog.plans[i]),
          ),
        ],
        if (catalog.reviews.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'What our patients say',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: catalog.reviews.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final review = catalog.reviews[index];
                return SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.78,
                  child: ReviewCard(
                    reviewerName: review.reviewerName,
                    reviewText: review.reviewText,
                    rating: review.rating,
                    dateLabel: _reviewDate(review.dateLabel),
                    avatarUrl: review.imageUrl,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openJoin(
    BuildContext context,
    WidgetRef ref,
    MembershipPlan plan,
  ) async {
    if (!plan.isJoinable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This plan cannot be purchased in-app.')),
      );
      return;
    }

    final loggedIn = ref.read(isLoggedInProvider);
    if (!loggedIn) {
      context.push(AppRoutes.loginPath(returnTo: AppRoutes.membership));
      return;
    }

    // Refresh profile so tier / left days are current before warning.
    await ref.read(authControllerProvider.notifier).refreshProfile();
    if (!context.mounted) return;

    final user = ref.read(currentUserProvider);
    if (user != null && user.membershipActive) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace current membership?'),
          content: Text(
            'You already have an active ${user.tierTitle} '
            '(${user.leftDays} day(s) left, '
            '${user.complimentaryUsed}/2 complimentary services used).\n\n'
            'Buying ${plan.title} will replace your current plan from today:\n'
            '• Remaining membership days will be lost (reset)\n'
            '• Complimentary services used will reset to 0\n'
            '• Your previous plan benefits will end immediately',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    await context.push(AppRoutes.membershipCheckout, extra: plan);
  }

  static String? _reviewDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat.yMMMd().format(parsed);
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.ochre, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.sage,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.ochre, thickness: 1)),
          ],
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            content,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.ink,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onJoin});

  final MembershipPlan plan;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final price = plan.priceLabel;
    final canJoin = plan.isJoinable;

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.heroImageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: plan.heroImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: AppColors.sageLight,
                ),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: AppColors.sageLight,
                  child: Center(
                    child: Icon(Icons.image_outlined, color: AppColors.inkMuted),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 56,
                  height: 3,
                  color: AppColors.ochre,
                ),
                for (final section in plan.sections) ...[
                  const SizedBox(height: 14),
                  if (section.heading.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        section.heading,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  for (final item in section.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.ochre,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.ink,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (price != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sageLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      price,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (canJoin) ...[
                  const SizedBox(height: 14),
                  AppButton(
                    label: plan.buttonLabel ?? 'Join Now',
                    onPressed: onJoin,
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
