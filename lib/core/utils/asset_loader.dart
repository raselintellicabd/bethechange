import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../network/api_result.dart';

/// Loads and decodes bundled JSON assets into typed models.
///
/// Feature repositories should call this instead of reading assets directly,
/// so error handling stays consistent with [ApiResult].
class AssetLoader {
  AssetLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Loads a JSON object asset and maps it with [parser].
  Future<ApiResult<T>> loadJsonObject<T>(
    String assetPath, {
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    try {
      final raw = await _bundle.loadString(assetPath);
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        return ApiFailure(
          message: 'Expected a JSON object in $assetPath.',
        );
      }

      return ApiSuccess(parser(decoded));
    } on FormatException catch (error) {
      return ApiFailure(
        message: 'Invalid JSON in $assetPath.',
        error: error,
      );
    } catch (error) {
      if (error is FlutterError) {
        return ApiFailure(
          message: 'Could not load asset $assetPath.',
          error: error,
        );
      }
      return ApiFailure(
        message: 'Failed to parse $assetPath.',
        error: error,
      );
    }
  }

  /// Loads a JSON array asset (or an object that wraps a list under [listKey]).
  Future<ApiResult<List<T>>> loadJsonList<T>(
    String assetPath, {
    required T Function(Map<String, dynamic> json) parser,
    String? listKey,
  }) async {
    try {
      final raw = await _bundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      final list = _extractList(decoded, listKey: listKey);

      if (list == null) {
        return ApiFailure(
          message: listKey == null
              ? 'Expected a JSON array in $assetPath.'
              : 'Expected a JSON array at "$listKey" in $assetPath.',
        );
      }

      final items = <T>[];
      for (final entry in list) {
        if (entry is! Map<String, dynamic>) {
          return ApiFailure(
            message: 'Expected list items to be objects in $assetPath.',
          );
        }
        items.add(parser(entry));
      }

      return ApiSuccess(items);
    } on FormatException catch (error) {
      return ApiFailure(
        message: 'Invalid JSON in $assetPath.',
        error: error,
      );
    } catch (error) {
      if (error is FlutterError) {
        return ApiFailure(
          message: 'Could not load asset $assetPath.',
          error: error,
        );
      }
      return ApiFailure(
        message: 'Failed to parse $assetPath.',
        error: error,
      );
    }
  }

  List<dynamic>? _extractList(Object? decoded, {String? listKey}) {
    if (listKey == null) {
      return decoded is List<dynamic> ? decoded : null;
    }

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final value = decoded[listKey];
    return value is List<dynamic> ? value : null;
  }
}
