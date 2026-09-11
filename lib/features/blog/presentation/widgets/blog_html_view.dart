import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/blog_html.dart';

class BlogHtmlView extends StatelessWidget {
  const BlogHtmlView({super.key, required this.blocks});

  final List<BlogContentBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++)
          _Block(
            block: blocks[i],
            isFirst: i == 0,
            bodyStyle: bodyStyle,
          ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.block,
    required this.isFirst,
    required this.bodyStyle,
  });

  final BlogContentBlock block;
  final bool isFirst;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      BlogHeading(:final text, :final level) => Padding(
          padding: EdgeInsets.only(
            top: isFirst ? 0 : AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: Text(text, style: _headingStyle(context, level)),
        ),
      BlogParagraph(:final text) => Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : AppSpacing.md),
          child: Text(text, style: bodyStyle),
        ),
      BlogBulletList(:final items) => Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: bodyStyle),
                      Expanded(child: Text(item, style: bodyStyle)),
                    ],
                  ),
                ),
            ],
          ),
        ),
    };
  }

  TextStyle _headingStyle(BuildContext context, int level) {
    final theme = Theme.of(context);
    final base = level <= 4
        ? theme.textTheme.titleLarge
        : theme.textTheme.titleMedium;
    return (base ?? const TextStyle()).copyWith(
      color: AppColors.forestDark,
      height: 1.3,
    );
  }
}
