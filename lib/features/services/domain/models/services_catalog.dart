import 'service.dart';

class ServicesCatalog {
  const ServicesCatalog({
    required this.services,
    this.title = '',
    this.content = '',
  });

  final String title;
  final String content;
  final List<Service> services;

  Service? byId(String id) {
    for (final service in services) {
      if (service.id == id || service.slug == id) return service;
    }
    return null;
  }

  factory ServicesCatalog.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as List<dynamic>? ?? const [])
        .map((item) => Service.fromJson(item as Map<String, dynamic>))
        .toList();
    return ServicesCatalog(
      title: (json['title'] as String?)?.trim() ?? '',
      content: (json['content'] as String?)?.trim() ?? '',
      services: services,
    );
  }
}
