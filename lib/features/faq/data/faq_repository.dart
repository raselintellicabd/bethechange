import '../../../core/network/api_result.dart';
import '../../../core/utils/asset_loader.dart';
import '../domain/models/faq_catalog.dart';

class FaqRepository {
  FaqRepository({AssetLoader? assetLoader})
      : _assetLoader = assetLoader ?? AssetLoader();

  static const String assetPath = 'assets/data/faq.json';

  final AssetLoader _assetLoader;

  Future<ApiResult<FaqCatalog>> getFaq() {
    return _assetLoader.loadJsonObject(
      assetPath,
      parser: FaqCatalog.fromJson,
    );
  }
}
