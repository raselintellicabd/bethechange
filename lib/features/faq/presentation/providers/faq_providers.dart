import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/faq_repository.dart';
import '../../domain/models/faq_catalog.dart';

final faqRepositoryProvider = Provider<FaqRepository>((ref) {
  return FaqRepository();
});

final faqCatalogProvider = FutureProvider<FaqCatalog>((ref) async {
  final result = await ref.watch(faqRepositoryProvider).getFaq();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
