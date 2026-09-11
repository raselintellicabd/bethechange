import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/about_repository.dart';
import '../../data/doctor_repository.dart';
import '../../domain/models/about_content.dart';
import '../../domain/models/doctor_profile.dart';

final aboutRepositoryProvider = Provider<AboutRepository>((ref) {
  return AboutRepository(ref.watch(apiClientProvider));
});

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(apiClientProvider));
});

final doctorBySlugProvider =
    FutureProvider.family<DoctorProfile, String>((ref, slug) async {
  final result = await ref.watch(doctorRepositoryProvider).getDoctor(slug);
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});

final aboutContentProvider = FutureProvider<AboutContent>((ref) async {
  final result = await ref.watch(aboutRepositoryProvider).getAboutContent();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
