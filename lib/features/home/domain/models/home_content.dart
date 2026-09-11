import '../../../about/domain/models/about_section.dart';
import '../../../about/domain/models/doctor_profile.dart';
import '../../../about/domain/models/review.dart';
import 'home_api_mapper.dart';

class HomeContent {
  const HomeContent({
    required this.sections,
    required this.doctors,
    required this.reviews,
    this.aboutSegmentLabels = const {},
    this.sectionImages = const {},
  });

  final List<AboutSection> sections;
  final List<DoctorProfile> doctors;
  final List<Review> reviews;
  final Map<String, String> aboutSegmentLabels;
  final Map<String, String> sectionImages;

  DoctorProfile? doctorById(String id) {
    for (final doctor in doctors) {
      if (doctor.id == id) return doctor;
    }
    return null;
  }

  String segmentLabel(String id, String fallbackTitle) {
    final label = aboutSegmentLabels[id];
    if (label != null && label.trim().isNotEmpty) return label;
    final parts = fallbackTitle.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? fallbackTitle : parts.first;
  }

  String? sectionImageUrl(String id) {
    final url = sectionImages[id]?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  factory HomeContent.fromJson(Map<String, dynamic> json) {
    final payload = HomeApiMapper.parse(json);
    return HomeContent(
      sections: payload.sections,
      doctors: payload.doctors,
      reviews: payload.reviews,
      aboutSegmentLabels: payload.aboutSegmentLabels,
      sectionImages: payload.sectionImages,
    );
  }
}
