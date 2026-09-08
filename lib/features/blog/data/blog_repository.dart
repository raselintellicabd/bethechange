import '../../../core/network/api_result.dart';
import '../../../core/utils/asset_loader.dart';
import '../domain/models/blog_article.dart';
import '../domain/models/blog_catalog.dart';

class BlogRepository {
  BlogRepository({AssetLoader? assetLoader})
      : _assetLoader = assetLoader ?? AssetLoader();

  static const String assetPath = 'assets/data/blog.json';

  final AssetLoader _assetLoader;

  Future<ApiResult<BlogCatalog>> getArticles() {
    return _assetLoader.loadJsonObject(
      assetPath,
      parser: BlogCatalog.fromJson,
    );
  }

  Future<ApiResult<BlogArticle>> getArticleById(String id) async {
    final catalogResult = await getArticles();
    return catalogResult.when(
      success: (catalog) {
        final article = catalog.byId(id);
        if (article == null) {
          return ApiFailure(message: 'Article "$id" was not found.');
        }
        return ApiSuccess(article);
      },
      failure: (message, statusCode) => ApiFailure(
        message: message,
        statusCode: statusCode,
      ),
    );
  }
}
