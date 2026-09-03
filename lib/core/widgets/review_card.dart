import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_card.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.reviewerName,
    required this.reviewText,
    this.rating = 5,
    this.dateLabel,
  });

  final String reviewerName;
  final String reviewText;
  final double rating;
  final String? dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(reviewerName, style: theme.textTheme.titleMedium),
              ),
              if (dateLabel != null)
                Text(dateLabel!, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: List.generate(5, (index) {
              final filled = index < rating.round();
              return Icon(
                filled ? Icons.star : Icons.star_border,
                size: AppSpacing.iconSm,
                color: theme.colorScheme.tertiary,
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(reviewText, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
