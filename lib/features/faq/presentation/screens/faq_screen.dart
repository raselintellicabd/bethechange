import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/faq_providers.dart';

/// FAQ accordion. UI label is always **FAQ**.
class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(faqCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.chatbot),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask a question'),
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

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl + AppSpacing.xl,
            ),
            itemCount: catalog.items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'Common questions about appointments, therapies, and office policies.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                );
              }

              final item = catalog.items[index - 1];
              return Card(
                margin: EdgeInsets.zero,
                child: ExpansionTile(
                  key: ValueKey(item.id),
                  title: Text(
                    item.question,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.answer,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
