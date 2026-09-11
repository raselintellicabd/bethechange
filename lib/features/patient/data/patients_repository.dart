import '../../../core/network/api_result.dart';
import '../../../core/network/mock_api_assets.dart';
import '../../../core/utils/asset_loader.dart';
import '../domain/models/patients_content.dart';

/// Patient hub content is bundled. There is no patients API yet.
class PatientsRepository {
  PatientsRepository({AssetLoader? loader}) : _loader = loader ?? AssetLoader();

  final AssetLoader _loader;

  Future<ApiResult<PatientsContent>> getPatientsContent() {
    return _loader.loadJsonObject(
      MockApiAssets.patients,
      parser: PatientsContent.fromJson,
    );
  }
}
