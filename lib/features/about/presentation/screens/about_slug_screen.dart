import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/about_providers.dart';
import 'about_page_screen.dart';
import 'doctor_detail_screen.dart';

/// Resolves `/about/:slug` to an About page or a doctor profile.
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
      error: (_, _) => DoctorDetailScreen(doctorId: slug),
      data: (catalog) {
        if (catalog.pageBySlug(slug) != null) {
          return AboutPageScreen(slug: slug);
        }
        return DoctorDetailScreen(doctorId: slug);
      },
    );
  }
}
