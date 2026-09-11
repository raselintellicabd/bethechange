import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../clinic/data/clinic_repository.dart';
import '../../../clinic/domain/models/clinic_info.dart';
import '../../../../core/utils/asset_loader.dart';
import '../../data/patients_repository.dart';
import '../../domain/models/patients_content.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>((ref) {
  return PatientsRepository();
});

final patientsContentProvider = FutureProvider<PatientsContent>((ref) async {
  final result =
      await ref.watch(patientsRepositoryProvider).getPatientsContent();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});

/// Portal and shop links. Local only — not an API call.
final patientClinicLinksProvider = FutureProvider<ClinicInfo>((ref) async {
  final result = await AssetLoader().loadJsonObject(
    ClinicRepository.bundledAsset,
    parser: ClinicInfo.fromJson,
  );
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
