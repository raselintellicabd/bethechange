import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services_repository.dart';
import '../../domain/models/service.dart';
import '../../domain/models/services_catalog.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository();
});

final servicesCatalogProvider = FutureProvider<ServicesCatalog>((ref) async {
  final result = await ref.watch(servicesRepositoryProvider).getServices();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});

final serviceByIdProvider =
    FutureProvider.family<Service, String>((ref, id) async {
  final catalog = await ref.watch(servicesCatalogProvider.future);
  final service = catalog.byId(id);
  if (service == null) {
    throw Exception('Service "$id" was not found.');
  }
  return service;
});
