import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../domain/models/labeled_list_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'image_with_caption.dart';
import 'section_header.dart';

class BulletOrIconListSection extends StatelessWidget {
  const BulletOrIconListSection({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
    this.imageUrl,
    this.fallbackIcon = Icons.check_circle_outline,
  });

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final List<LabeledListItem> items;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        if (imageUrl != null && imageUrl!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ImageWithCaption(imageUrl: imageUrl!),
        ],
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < items.length; i++) ...[
          _LabeledListItemTile(
            item: items[i],
            fallbackIcon: fallbackIcon,
          ),
          if (i < items.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
        if (items.isEmpty)
          Text(
            'No items available.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _LabeledListItemTile extends StatelessWidget {
  const _LabeledListItemTile({
    required this.item,
    required this.fallbackIcon,
  });

  final LabeledListItem item;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ItemIcon(iconUrl: item.iconUrl, fallbackIcon: fallbackIcon),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: theme.textTheme.titleSmall),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(item.description!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({
    required this.iconUrl,
    required this.fallbackIcon,
  });

  final String? iconUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (iconUrl == null || iconUrl!.isEmpty) {
      return Icon(
        fallbackIcon,
        color: AppColors.primary,
        size: AppSpacing.iconMd,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: CachedNetworkImage(
        imageUrl: iconUrl!,
        width: AppSpacing.iconLg,
        height: AppSpacing.iconLg,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          width: AppSpacing.iconLg,
          height: AppSpacing.iconLg,
          child: Center(
            child: SizedBox(
              width: AppSpacing.iconSm,
              height: AppSpacing.iconSm,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          fallbackIcon,
          color: AppColors.primary,
          size: AppSpacing.iconMd,
        ),
      ),
    );
  }
}
