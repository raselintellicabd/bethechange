import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/home_repository.dart';
import '../../domain/models/home_content.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(apiClientProvider));
});

final homeContentProvider = FutureProvider<HomeContent>((ref) async {
  final result = await ref.watch(homeRepositoryProvider).getHomeContent();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
