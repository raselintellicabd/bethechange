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
import '../../../about/domain/models/review.dart';
import '../../domain/models/faq_catalog.dart';
import '../../domain/models/faq_item.dart';
import '../providers/faq_providers.dart';

/// FAQ accordion driven by `GET /api/v1/faq/`. App bar label stays **FAQ**.
class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(faqCatalogProvider);

    return Scaffold(
      appBar: AppAppBar.text('FAQ'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.chatbot),
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask assistant'),
      ),
      body: catalogAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading FAQ...'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(faqCatalogProvider),
        ),
        data: (catalog) {
          if (catalog.items.isEmpty &&
              catalog.sections.isEmpty &&
              catalog.policies == null) {
            return const ErrorStateWidget(
              title: 'No FAQ items',
              message: 'FAQ content is unavailable.',
            );
          }

          return _FaqBody(
            catalog: catalog,
            query: _query,
            searchController: _searchController,
            onQueryChanged: (value) => setState(() => _query = value.trim()),
          );
        },
      ),
    );
  }
}

class _FaqBody extends StatelessWidget {
  const _FaqBody({
    required this.catalog,
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
  });

  final FaqCatalog catalog;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final searching = query.isNotEmpty;
    final sections = _matchingSections();
    final extras = _matchingItems(catalog.ungroupedItems);
    final policies = _matchingPolicies();
    final hasMatches =
        sections.isNotEmpty || extras.isNotEmpty || policies != null;
    final showPageChrome = !searching;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl + AppSpacing.xl,
      ),
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search questions…',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: onQueryChanged,
        ),
        if (showPageChrome &&
            catalog.title.trim().isNotEmpty &&
            catalog.title.trim().toLowerCase() != 'faq') ...[
          const SizedBox(height: AppSpacing.md),
          Text(catalog.title, style: AppTextStyles.headlineLarge),
        ],
        if (!hasMatches)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(
              'No matching questions.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkMuted),
            ),
          ),
        for (final section in sections) ...[
          if (section.title.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(section.title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
          ] else
            const SizedBox(height: AppSpacing.md),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FaqTile(item: item),
            ),
        ],
        if (extras.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          for (final item in extras)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FaqTile(item: item),
            ),
        ],
        if (policies != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _PoliciesTile(policies: policies),
        ],
        if (showPageChrome && catalog.reviews.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('What our patients say'),
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
                    dateLabel: _reviewDate(review),
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

  List<FaqSection> _matchingSections() {
    return [
      for (final section in catalog.displaySections)
        if (_sectionMatches(section))
          FaqSection(
            id: section.id,
            title: section.title,
            items: _matchingItems(section.items, includeAll: _titleMatches(section.title)),
          ),
    ].where((section) => section.items.isNotEmpty).toList();
  }

  bool _sectionMatches(FaqSection section) {
    if (query.isEmpty) return section.items.isNotEmpty;
    if (_titleMatches(section.title)) return section.items.isNotEmpty;
    return _matchingItems(section.items).isNotEmpty;
  }

  bool _titleMatches(String title) {
    if (query.isEmpty) return false;
    return title.toLowerCase().contains(query.toLowerCase());
  }

  List<FaqItem> _matchingItems(List<FaqItem> items, {bool includeAll = false}) {
    if (query.isEmpty || includeAll) return items;
    final q = query.toLowerCase();
    return items
        .where(
          (item) =>
              item.question.toLowerCase().contains(q) ||
              item.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  FaqPolicies? _matchingPolicies() {
    final policies = catalog.policies;
    if (policies == null) return null;
    if (query.isEmpty) return policies;
    final q = query.toLowerCase();
    if (policies.title.toLowerCase().contains(q) ||
        policies.content.toLowerCase().contains(q)) {
      return policies;
    }
    return null;
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey(item.id),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            item.question,
            style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(item.answer, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoliciesTile extends StatelessWidget {
  const _PoliciesTile({required this.policies});

  final FaqPolicies policies;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey(policies.id),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            policies.title,
            style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(policies.content, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
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
