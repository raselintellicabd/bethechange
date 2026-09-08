import 'package:flutter/material.dart';

import '../domain/models/recommended_book.dart';
import '../theme/app_spacing.dart';
import 'book_card.dart';
import 'empty_state_widget.dart';
import 'section_header.dart';

/// Horizontal list of [BookCard]s for Conditions/Services detail pages.
class RecommendedBooksSection extends StatelessWidget {
  const RecommendedBooksSection({
    super.key,
    required this.books,
    this.title = 'Recommended Books',
    this.subtitle,
    this.onBookTap,
  });

  final List<RecommendedBook> books;
  final String title;
  final String? subtitle;
  final void Function(RecommendedBook book)? onBookTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.sm),
        if (books.isEmpty)
          const EmptyStateWidget(
            title: 'No books listed',
            message: 'Recommended books will appear here when available.',
            icon: Icons.menu_book_outlined,
          )
        else
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final book = books[index];
                return BookCard(
                  book: book,
                  onTap: onBookTap == null ? null : () => onBookTap!(book),
                );
              },
            ),
          ),
      ],
    );
  }
}
