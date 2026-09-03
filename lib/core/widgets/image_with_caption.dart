import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'loading_indicator.dart';

class ImageWithCaption extends StatelessWidget {
  const ImageWithCaption({
    super.key,
    required this.imageUrl,
    this.caption,
    this.height = 180,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final String? caption;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
