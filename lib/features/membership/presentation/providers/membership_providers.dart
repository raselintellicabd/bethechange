import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/membership_repository.dart';
import '../../domain/models/membership_catalog.dart';

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(ref.watch(apiClientProvider));
});

final membershipCatalogProvider = FutureProvider<MembershipCatalog>((ref) async {
  final result = await ref.watch(membershipRepositoryProvider).getMemberships();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
