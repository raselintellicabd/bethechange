import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_card.dart';

class DoctorProfileCard extends StatelessWidget {
  const DoctorProfileCard({
    super.key,
    required this.name,
    required this.title,
    this.imageUrl,
    this.bio,
    this.onTap,
  });

  final String name;
  final String title;
  final String? imageUrl;
  final String? bio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null,
            child: imageUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: theme.textTheme.titleLarge,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(title, style: theme.textTheme.bodySmall),
                if (bio != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    bio!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
