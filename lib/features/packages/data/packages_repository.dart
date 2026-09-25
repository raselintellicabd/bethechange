import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/api_result.dart';
import '../domain/models/package_bundle.dart';

/// Live package/bundle APIs (`/api/v1/packages/…`).
class PackagesRepository {
  PackagesRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<PackageCatalog>> listPackages() {
    return _client.get(
      '${ApiPaths.packages}/',
      parser: (data) =>
          PackageCatalog.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PackageBundle>> getPackage(String slug) {
    return _client.get(
      ApiPaths.packageDetail(slug),
      parser: (data) =>
          PackageBundle.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PackageQuote>> getQuote(String slug) {
    return _client.get(
      ApiPaths.packageQuote(slug),
      parser: (data) =>
          PackageQuote.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PackagePaymentSession>> createPaymentSession(String slug) {
    return _client.post(
      ApiPaths.packagePaymentSession(slug),
      data: const <String, dynamic>{},
      parser: (data) =>
          PackagePaymentSession.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PackageBookingResult>> bookPackage({
    required String slug,
    required String paymentSessionId,
    required String fullName,
    required String email,
    required String phone,
    required String consultationMode,
    required List<PackageSelection> selections,
  }) {
    return _client.post(
      ApiPaths.packageBook(slug),
      data: {
        'payment_session_id': paymentSessionId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'consultation_mode': consultationMode,
        'selections': selections.map((s) => s.toJson()).toList(),
      },
      parser: (data) =>
          PackageBookingResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
