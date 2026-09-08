import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/blog_repository.dart';
import '../../domain/models/blog_article.dart';
import '../../domain/models/blog_catalog.dart';

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository();
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
  final catalog = await ref.watch(blogCatalogProvider.future);
  final article = catalog.byId(id);
  if (article == null) {
    throw Exception('Article "$id" was not found.');
  }
  return article;
});
