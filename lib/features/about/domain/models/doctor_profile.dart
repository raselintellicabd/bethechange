class DoctorProfile {
  const DoctorProfile({
    required this.id,
    required this.name,
    required this.title,
    this.imageUrl,
    this.bio,
  });

  final String id;
  final String name;
  final String title;
  final String? imageUrl;
  final String? bio;

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
