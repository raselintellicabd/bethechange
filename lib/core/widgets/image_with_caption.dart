import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'loading_indicator.dart';

/// Remote image with disk/memory caching.
///
/// Phase K.1: prefer this (or [CachedNetworkImage]) over uncached
/// `Image.network` for any remote content.
class ImageWithCaption extends StatelessWidget {
  const ImageWithCaption({
    super.key,
    required this.imageUrl,
    this.caption,
    this.semanticLabel,
    this.height = 180,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final String? caption;
  final String? semanticLabel;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel ?? caption ?? 'Content image',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: fit,
                placeholder: (context, url) => const LoadingIndicator(),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: AppColors.surfaceMuted,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(caption!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
