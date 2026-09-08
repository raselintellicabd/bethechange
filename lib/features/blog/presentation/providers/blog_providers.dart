import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/blog_repository.dart';
import '../../domain/models/blog_article.dart';
import '../../domain/models/blog_catalog.dart';

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository(ref.watch(apiClientProvider));
});

final blogCatalogProvider = FutureProvider<BlogCatalog>((ref) async {
  final result = await ref.watch(blogRepositoryProvider).getArticles();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});

final blogArticleByIdProvider =
    FutureProvider.family<BlogArticle, String>((ref, id) async {
  final result = await ref.watch(blogRepositoryProvider).getArticleById(id);
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
