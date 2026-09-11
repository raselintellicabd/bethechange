import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/clinic_info.dart';

class ClinicRepository {
  ClinicRepository(this._client, {AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final ApiClient _client;
  final AssetBundle _bundle;

  static const bundledAsset = 'assets/data/clinic.json';

  Future<ApiResult<ClinicInfo>> getClinicInfo() async {
    final result = await _client.get(
      ApiPaths.clinic,
      parser: (data) => ClinicInfo.fromJson(data as Map<String, dynamic>),
    );
    if (result is ApiSuccess<ClinicInfo>) return result;
    if (result is ApiFailure<ClinicInfo> && result.statusCode == 404) {
      final bundled = await _bundledClinic();
      if (bundled != null) return ApiSuccess(bundled);
    }
    return result;
  }

  Future<ClinicInfo?> _bundledClinic() async {
    try {
      final raw = await _bundle.loadString(bundledAsset);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ClinicInfo.fromJson(decoded);
      }
      if (decoded is Map) {
        return ClinicInfo.fromJson(
          decoded.map((key, value) => MapEntry('$key', value)),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
