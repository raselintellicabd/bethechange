import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../../../features/about/presentation/providers/about_providers.dart';
import '../../../../features/conditions/presentation/providers/conditions_providers.dart';
import '../../../../features/services/presentation/providers/services_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);
    final conditionsAsync = ref.watch(conditionsCatalogProvider);
    final servicesAsync = ref.watch(servicesCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Be The Change'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppIconButton(
              icon: Icons.menu,
              tooltip: 'About',
              onPressed: () => context.push(AppRoutes.about),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const AppHeroBanner(
            tag: 'Integrative & naturopathic care',
            title: 'Get to the root cause of your health concerns.',
            height: 190,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AppButton(
              label: 'Request an appointment',
              onPressed: () => context.push(
                AppRoutes.appointmentPath(AppRoutes.clinicSourceContext),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: SectionTitle('Conditions we treat'),
          ),
          conditionsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: LoadingIndicator(),
            ),
            error: (e, _) => ErrorStateWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(conditionsCatalogProvider),
            ),
            data: (catalog) => SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: catalog.conditions.take(6).length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final c = catalog.conditions[index];
                  return HorizontalContentCard(
                    title: c.name,
                    subtitle: c.summary,
                    thumbColor: AppColors.thumbPalette[
                        index % AppColors.thumbPalette.length],
                    onTap: () => context.push(
                      AppRoutes.conditionDetailPath(c.id),
                    ),
                  );
                },
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: SectionTitle('Featured therapies'),
          ),
          servicesAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: LoadingIndicator(),
            ),
            error: (e, _) => const SizedBox.shrink(),
            data: (catalog) => SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: catalog.services.take(5).length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final s = catalog.services[index];
                  return HorizontalContentCard(
                    title: s.name,
                    subtitle: s.summary,
                    thumbColor: AppColors.thumbPalette[
                        (index + 3) % AppColors.thumbPalette.length],
                    onTap: () => context.push(
                      AppRoutes.serviceDetailPath(s.id),
                    ),
                  );
                },
              ),
            ),
          ),
          aboutAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (content) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                    child: SectionTitle('Meet our doctors'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (var i = 0; i < content.doctors.take(2).length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.sage,
                                      foregroundColor: Colors.white,
                                      child: Text(
                                        _initials(content.doctors[i].name),
                                        style: AppTextStyles.labelMedium
                                            .copyWith(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      content.doctors[i].name,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.labelMedium
                                          .copyWith(fontSize: 11.5),
                                    ),
                                    Text(
                                      content.doctors[i].title,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(fontSize: 9.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (content.reviews.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                      child: SectionTitle('What our patients say'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child:                       _ReviewSnippet(
                        name: content.reviews.first.reviewerName,
                        text: content.reviews.first.reviewText,
                      ),
                    ),
                  ] else
                    const SizedBox(height: AppSpacing.lg),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ReviewSnippet extends StatelessWidget {
  const _ReviewSnippet({required this.name, required this.text});

  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.sage,
              foregroundColor: Colors.white,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(name, style: AppTextStyles.labelMedium.copyWith(fontSize: 11.5)),
            const SizedBox(width: 8),
            Text('★★★★★', style: AppTextStyles.labelSmall.copyWith(color: AppColors.ochre)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}
