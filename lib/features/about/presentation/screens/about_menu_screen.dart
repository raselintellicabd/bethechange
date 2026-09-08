import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../providers/about_providers.dart';
import '../widgets/about_content_view.dart';

/// About menu — list of sections opened from Home ☰.
class AboutMenuScreen extends ConsumerWidget {
  const AboutMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: false,
      ),
      body: aboutAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading About...'),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(aboutContentProvider),
        ),
        data: (content) {
          if (content.sections.isEmpty) {
            return const ErrorStateWidget(
              title: 'No content',
              message: 'About sections are missing from the content file.',
            );
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Learn about our practice, philosophy, and care process.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                ),
              ),
              for (var i = 0; i < content.sections.length; i++)
                ListRowTile(
                  title: content.sections[i].title,
                  subtitle: _sectionBlurb(content.sections[i].id),
                  thumbColor: AppColors
                      .thumbPalette[i % AppColors.thumbPalette.length],
                  onTap: () => context.push(
                    AppRoutes.aboutSectionPath(content.sections[i].id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _sectionBlurb(String id) {
    return switch (id) {
      'our-practice' => 'Who we are and how we care for patients.',
      'naturopathic-medicine' => 'The foundations of naturopathic medicine.',
      'integrative-medicine' =>
        'How integrative care brings modalities together.',
      'our-process' => 'What to expect from your visits.',
      _ => 'Tap to read more.',
    };
  }
}

/// About section detail with optional segment switcher across sections.
class AboutSectionScreen extends ConsumerWidget {
  const AboutSectionScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return aboutAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: const LoadingIndicator(message: 'Loading About...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(aboutContentProvider),
        ),
      ),
      data: (content) {
        final section = content.sectionById(sectionId);
        if (section == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('About')),
            body: const ErrorStateWidget(
              title: 'Not found',
              message: 'That About section could not be found.',
            ),
          );
        }

        final sectionIndex =
            content.sections.indexWhere((s) => s.id == sectionId);

        return Scaffold(
          appBar: AppBar(
            title: Text(section.title),
            centerTitle: false,
          ),
          body: Column(
            children: [
              if (content.sections.length > 1)
                SegmentControl(
                  labels: [
                    for (final s in content.sections)
                      s.title.split(' ').first,
                  ],
                  selectedIndex: sectionIndex < 0 ? 0 : sectionIndex,
                  onChanged: (index) {
                    context.go(
                      AppRoutes.aboutSectionPath(content.sections[index].id),
                    );
                  },
                ),
              Expanded(
                child: AboutContentView(
                  section: section,
                  content: content,
                  showHero: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
