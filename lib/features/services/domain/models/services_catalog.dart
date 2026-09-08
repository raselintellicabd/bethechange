import 'service.dart';

class ServicesCatalog {
  const ServicesCatalog({required this.services});

  final List<Service> services;

  Service? byId(String id) {
    for (final service in services) {
      if (service.id == id) return service;
    }
    return null;
  }

  factory ServicesCatalog.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as List<dynamic>? ?? const [])
        .map((item) => Service.fromJson(item as Map<String, dynamic>))
        .toList();
    return ServicesCatalog(services: services);
  }
}
