class Review {
  const Review({
    required this.reviewerName,
    required this.reviewText,
    this.rating = 5,
    this.dateLabel,
    this.imageUrl,
  });

  final String reviewerName;
  final String reviewText;
  final double rating;
  final String? dateLabel;
  final String? imageUrl;

  factory Review.fromJson(Map<String, dynamic> json) {
    final imageUrl = (json['imageUrl'] as String?)?.trim() ??
        (json['img-url'] as String?)?.trim();

    return Review(
      reviewerName: (json['reviewerName'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          '',
      reviewText: (json['reviewText'] as String?)?.trim() ??
          (json['comment'] as String?)?.trim() ??
          '',
      rating: (json['rating'] as num? ?? json['star'] as num?)?.toDouble() ?? 5,
      dateLabel: (json['dateLabel'] as String?)?.trim() ??
          (json['date'] as String?)?.trim(),
      imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
    );
  }
}
