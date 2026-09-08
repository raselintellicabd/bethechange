import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/patients_repository.dart';
import '../../domain/models/patients_content.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>((ref) {
  return PatientsRepository(ref.watch(apiClientProvider));
});

final patientsContentProvider = FutureProvider<PatientsContent>((ref) async {
  final result =
      await ref.watch(patientsRepositoryProvider).getPatientsContent();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
