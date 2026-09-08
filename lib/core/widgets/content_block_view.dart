import 'package:flutter/material.dart';

import '../domain/models/content_block.dart';
import '../theme/app_spacing.dart';
import 'image_with_caption.dart';
import 'section_header.dart';

/// Renders a shared [ContentBlock] (title, optional body, optional image).
class ContentBlockView extends StatelessWidget {
  const ContentBlockView({
    super.key,
    required this.block,
    this.showTitleAsHeader = true,
  });

  final ContentBlock block;
  final bool showTitleAsHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitleAsHeader)
          SectionHeader(title: block.title)
        else
          Text(block.title, style: theme.textTheme.titleMedium),
        if (block.imageUrl != null && block.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ImageWithCaption(imageUrl: block.imageUrl!),
        ],
        if (block.body != null && block.body!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(block.body!, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }
}
