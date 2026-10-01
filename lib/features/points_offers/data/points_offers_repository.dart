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
    required String consultationMode,
    required String fullName,
    required String email,
    required String phone,
    String? date,
    int? timeMinutes,
    int? slotCount,
    int? machineId,
    List<Map<String, dynamic>>? visits,
  }) {
    return _client.post(
      ApiPaths.pointsOfferBook(id),
      data: {
        'consultation_mode': consultationMode,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        if (machineId != null) 'machine_id': machineId,
        if (visits != null && visits.length > 1)
          'visits': visits
        else ...{
          if (date != null) 'date': date,
          if (timeMinutes != null) 'time_minutes': timeMinutes,
          if (slotCount != null) 'slot_count': slotCount,
        },
      },
      parser: (data) =>
          PointOfferClaimResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
