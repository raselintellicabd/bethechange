import 'about_section.dart';
import 'doctor_profile.dart';
import 'review.dart';

/// Full About feature payload loaded from bundled JSON (or later an API).
class AboutContent {
  const AboutContent({
    required this.sections,
    required this.doctors,
    required this.reviews,
    this.doctorsIntro,
    this.reviewSummaryLabel,
    this.reviewCount,
  });

  final List<AboutSection> sections;
  final List<DoctorProfile> doctors;
  final List<Review> reviews;
  final String? doctorsIntro;
  final String? reviewSummaryLabel;
  final int? reviewCount;

  AboutSection? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  DoctorProfile? doctorById(String id) {
    for (final doctor in doctors) {
      if (doctor.id == id) return doctor;
    }
    return null;
  }

  /// Home `/api/v1/home/` doctor ids are numeric. Bios still live on About,
  /// keyed by name slug, until that endpoint shares the same id.
  DoctorProfile? doctorForRoute(String routeId, {DoctorProfile? homeDoctor}) {
    final direct = doctorById(routeId);
    if (direct != null) return direct;
    if (homeDoctor == null) return null;
    return doctorById(DoctorProfile.slugFromName(homeDoctor.name)) ?? homeDoctor;
  }

  factory AboutContent.fromJson(Map<String, dynamic> json) {
    return AboutContent(
      doctorsIntro: json['doctorsIntro'] as String?,
      reviewSummaryLabel: json['reviewSummaryLabel'] as String?,
      reviewCount: json['reviewCount'] as int?,
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map((item) => AboutSection.fromJson(item as Map<String, dynamic>))
          .toList(),
      doctors: (json['doctors'] as List<dynamic>? ?? const [])
          .map((item) => DoctorProfile.fromJson(item as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .map((item) => Review.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
