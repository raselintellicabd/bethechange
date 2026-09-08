import '../../../core/network/api_result.dart';
import '../../../core/utils/asset_loader.dart';
import '../domain/models/about_content.dart';

class AboutRepository {
  AboutRepository({AssetLoader? assetLoader})
      : _assetLoader = assetLoader ?? AssetLoader();

  static const String assetPath = 'assets/data/about.json';

  final AssetLoader _assetLoader;

  Future<ApiResult<AboutContent>> getAboutContent() {
    return _assetLoader.loadJsonObject(
      assetPath,
      parser: AboutContent.fromJson,
    );
  }
}
