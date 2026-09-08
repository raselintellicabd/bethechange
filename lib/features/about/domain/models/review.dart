class Review {
  const Review({
    required this.reviewerName,
    required this.reviewText,
    this.rating = 5,
    this.dateLabel,
  });

  final String reviewerName;
  final String reviewText;
  final double rating;
  final String? dateLabel;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewerName: json['reviewerName'] as String,
      reviewText: json['reviewText'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 5,
      dateLabel: json['dateLabel'] as String?,
    );
  }
}
