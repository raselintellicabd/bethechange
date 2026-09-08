import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/clinic_repository.dart';
import '../../domain/models/clinic_info.dart';

final clinicRepositoryProvider = Provider<ClinicRepository>((ref) {
  return ClinicRepository(ref.watch(apiClientProvider));
});

final clinicInfoProvider = FutureProvider<ClinicInfo>((ref) async {
  final result = await ref.watch(clinicRepositoryProvider).getClinicInfo();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
