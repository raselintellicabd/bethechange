import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/about_repository.dart';
import '../../domain/models/about_content.dart';

final aboutRepositoryProvider = Provider<AboutRepository>((ref) {
  return AboutRepository();
});

final aboutContentProvider = FutureProvider<AboutContent>((ref) async {
  final result = await ref.watch(aboutRepositoryProvider).getAboutContent();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
