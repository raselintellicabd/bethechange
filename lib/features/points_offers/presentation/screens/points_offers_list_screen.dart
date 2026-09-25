import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/point_offer.dart';
import '../providers/points_offers_providers.dart';

/// Published points offers — entry from Patients tab.
class PointsOffersListScreen extends ConsumerWidget {
  const PointsOffersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(pointsOfferCatalogProvider);
    final loggedIn = ref.watch(authControllerProvider).isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppAppBar(
        title: const Text('Points offers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: catalogAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading offers…'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(pointsOfferCatalogProvider),
        ),
        data: (catalog) {
          if (catalog.results.isEmpty) {
            return const ErrorStateWidget(
              title: 'No offers',
              message: 'There are no points offers available right now.',
            );
          }
          final authPoints =
              ref.watch(authControllerProvider).user?.points;
          final displayBalance = loggedIn
              ? (authPoints ?? catalog.pointsBalance)
              : catalog.pointsBalance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              _BalanceBanner(
                balance: displayBalance,
                loggedIn: loggedIn,
                onRefresh: loggedIn
                    ? () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .refreshProfile();
                        ref.invalidate(pointsOfferCatalogProvider);
                      }
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < catalog.results.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                _OfferCard(
                  offer: catalog.results[i],
                  loggedIn: loggedIn,
                  pointsBalance: displayBalance,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BalanceBanner extends StatefulWidget {
  const _BalanceBanner({
    required this.balance,
    required this.loggedIn,
    this.onRefresh,
  });

  final int? balance;
  final bool loggedIn;
  final Future<void> Function()? onRefresh;

  @override
  State<_BalanceBanner> createState() => _BalanceBannerState();
}

class _BalanceBannerState extends State<_BalanceBanner> {
  bool _refreshing = false;

  Future<void> _handleRefresh() async {
    final onRefresh = widget.onRefresh;
    if (onRefresh == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      await onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.stars_outlined, color: AppColors.ochre),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.loggedIn
                        ? 'Your reward points'
                        : 'Sign in to claim offers',
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.loggedIn
                        ? '${widget.balance ?? 0} points available'
                        : 'Earn points when you pay for appointments by card.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.loggedIn && widget.onRefresh != null)
              IconButton(
                tooltip: 'Refresh points',
                onPressed: _refreshing ? null : _handleRefresh,
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: _refreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, color: AppColors.ochre),
              ),
            if (!widget.loggedIn)
              TextButton(
                onPressed: () => context.push(
                  AppRoutes.loginPath(returnTo: AppRoutes.pointsOffers),
                ),
                child: const Text('Log in'),
              ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.loggedIn,
    this.pointsBalance,
  });

  final PointOffer offer;
  final bool loggedIn;
  final int? pointsBalance;

  @override
  Widget build(BuildContext context) {
    final canClaim = loggedIn &&
        (pointsBalance != null
            ? pointsBalance! >= offer.requiredPoints
            : offer.canClaim);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (offer.categoryName.isNotEmpty)
              Text(
                offer.categoryName.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 0.5,
                ),
              ),
            if (offer.categoryName.isNotEmpty) const SizedBox(height: 4),
            Text(offer.serviceName, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${offer.durationDisplay} · List ${offer.listPriceDisplay}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${offer.requiredPoints} points',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.forest,
                    ),
                  ),
                ),
                AppButton(
                  label: canClaim
                      ? 'Claim'
                      : (loggedIn ? 'Need more points' : 'Sign in'),
                  expand: false,
                  onPressed: canClaim
                      ? () => context.push(
                            AppRoutes.pointsOfferBookPath(offer.id),
                          )
                      : (!loggedIn
                          ? () => context.push(
                                AppRoutes.loginPath(
                                  returnTo: AppRoutes.pointsOfferBookPath(
                                    offer.id,
                                  ),
                                ),
                              )
                          : null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
