import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/faq_providers.dart';

/// FAQ accordion. UI label is always **FAQ**.
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
      appBar: AppBar(
        title: const Text('FAQ'),
        centerTitle: false,
      ),
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
          if (catalog.items.isEmpty) {
            return const ErrorStateWidget(
              title: 'No FAQ items',
              message: 'FAQ content is missing from the data file.',
            );
          }

          final filtered = catalog.items.where((item) {
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return item.question.toLowerCase().contains(q) ||
                item.answer.toLowerCase().contains(q);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl + AppSpacing.xl,
            ),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search questions…',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                );
              }

              final item = filtered[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
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
                          child: Text(
                            item.answer,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
