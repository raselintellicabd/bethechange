import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_app_bar.dart';

/// Temporary placeholder used until feature screens are implemented.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.details,
  });

  final String title;
  final String? details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TODO', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                details ?? title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
