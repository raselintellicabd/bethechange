import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/services_repository.dart';
import '../../domain/models/service.dart';
import '../../domain/models/services_catalog.dart';

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  return ServicesRepository(ref.watch(apiClientProvider));
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
  final result = await ref.watch(servicesRepositoryProvider).getServiceById(id);
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
