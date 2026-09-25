import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/api_result.dart';
import '../domain/models/point_offer.dart';

/// Live points-offer APIs (`/api/v1/points-offers/…`).
class PointsOffersRepository {
  PointsOffersRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<PointOfferCatalog>> listOffers() {
    return _client.get(
      '${ApiPaths.pointsOffers}/',
      parser: (data) =>
          PointOfferCatalog.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PointOffer>> getOffer(int id) {
    return _client.get(
      ApiPaths.pointsOfferDetail(id),
      parser: (data) => PointOffer.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PointOfferClaimResult>> claimOffer({
    required int id,
    required String date,
    required int timeMinutes,
    required String consultationMode,
    required String fullName,
    required String email,
    required String phone,
  }) {
    return _client.post(
      ApiPaths.pointsOfferBook(id),
      data: {
        'date': date,
        'time_minutes': timeMinutes,
        'consultation_mode': consultationMode,
        'full_name': fullName,
        'email': email,
        'phone': phone,
      },
      parser: (data) =>
          PointOfferClaimResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
