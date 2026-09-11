import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/about_providers.dart';
import 'about_menu_screen.dart';
import 'doctor_detail_screen.dart';

/// Resolves `/about/:slug` to either a doctor profile or an About section.
class _HomeDoctorRoute extends ConsumerWidget {
  const _HomeDoctorRoute({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeContentProvider);
    return homeAsync.when(
      loading: () => Scaffold(
        appBar: AppAppBar.text('Doctor'),
        body: const LoadingIndicator(message: 'Loading…'),
      ),
      error: (_, _) => Scaffold(
        appBar: AppAppBar.text('About'),
        body: const ErrorStateWidget(
          title: 'Not found',
          message: 'That About page could not be found.',
        ),
      ),
      data: (home) {
        if (home.doctorById(slug) == null) {
          return Scaffold(
            appBar: AppAppBar.text('About'),
            body: const ErrorStateWidget(
              title: 'Not found',
              message: 'That About page could not be found.',
            ),
          );
        }
        return DoctorDetailScreen(doctorId: slug);
      },
    );
  }
}

class AboutSlugScreen extends ConsumerWidget {
  const AboutSlugScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aboutAsync = ref.watch(aboutContentProvider);

    return aboutAsync.when(
      loading: () => Scaffold(
        appBar: AppAppBar.text('About'),
        body: const LoadingIndicator(message: 'Loading…'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppAppBar.text('About'),
        body: ErrorStateWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(aboutContentProvider),
        ),
      ),
      data: (content) {
        if (content.doctorById(slug) != null) {
          return DoctorDetailScreen(doctorId: slug);
        }
        if (content.sectionById(slug) != null) {
          return AboutSectionScreen(sectionId: slug);
        }
        return _HomeDoctorRoute(slug: slug);
      },
    );
  }
}
