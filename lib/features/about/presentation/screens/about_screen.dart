import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/about_providers.dart';
import '../widgets/about_content_view.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return aboutAsync.when(
      loading: () => const Scaffold(
        body: LoadingIndicator(message: 'Loading About...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(aboutContentProvider),
        ),
      ),
      data: (content) {
        if (content.sections.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('About')),
            body: const ErrorStateWidget(
              title: 'No content',
              message: 'About sections are missing from the content file.',
            ),
          );
        }

        return DefaultTabController(
          length: content.sections.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('About'),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final section in content.sections)
                    Tab(text: section.title),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                for (final section in content.sections)
                  KeepAliveAboutTab(
                    child: AboutContentView(
                      section: section,
                      content: content,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class KeepAliveAboutTab extends StatefulWidget {
  const KeepAliveAboutTab({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAliveAboutTab> createState() => _KeepAliveAboutTabState();
}

class _KeepAliveAboutTabState extends State<KeepAliveAboutTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: widget.child,
    );
  }
}
