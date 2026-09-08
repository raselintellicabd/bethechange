import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/blog_article.dart';
import '../domain/models/blog_catalog.dart';

class BlogRepository {
  BlogRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<BlogCatalog>> getArticles() {
    return _client.get(
      ApiPaths.blog,
      parser: (data) => BlogCatalog.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<BlogArticle>> getArticleById(String id) {
    return _client.get(
      ApiPaths.blogArticle(id),
      parser: (data) => BlogArticle.fromJson(data as Map<String, dynamic>),
    );
  }
}
