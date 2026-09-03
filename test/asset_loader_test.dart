import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/utils/asset_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssetLoader', () {
    test('loads sample.json object and list items', () async {
      final loader = AssetLoader();

      final objectResult = await loader.loadJsonObject<Map<String, dynamic>>(
        'assets/data/sample.json',
        parser: (json) => json,
      );

      expect(objectResult, isA<ApiSuccess<Map<String, dynamic>>>());
      final object = (objectResult as ApiSuccess<Map<String, dynamic>>).data;
      expect(object['version'], 1);
      expect(object['name'], 'BeTheChange sample content');

      final listResult = await loader.loadJsonList<_SampleItem>(
        'assets/data/sample.json',
        listKey: 'items',
        parser: _SampleItem.fromJson,
      );

      expect(listResult, isA<ApiSuccess<List<_SampleItem>>>());
      final items = (listResult as ApiSuccess<List<_SampleItem>>).data;
      expect(items, hasLength(1));
      expect(items.first.id, 'demo');
      expect(items.first.title, 'Demo Item');
    });

    test('returns failure for missing asset', () async {
      final loader = AssetLoader();

      final result = await loader.loadJsonObject<Map<String, dynamic>>(
        'assets/data/does_not_exist.json',
        parser: (json) => json,
      );

      expect(result, isA<ApiFailure<Map<String, dynamic>>>());
      final failure = result as ApiFailure<Map<String, dynamic>>;
      expect(failure.message, contains('Could not load asset'));
    });

    test('returns failure for invalid JSON', () async {
      final bundle = _FakeAssetBundle({
        'assets/data/broken.json': '{ not-valid-json',
      });
      final loader = AssetLoader(bundle: bundle);

      final result = await loader.loadJsonObject<Map<String, dynamic>>(
        'assets/data/broken.json',
        parser: (json) => json,
      );

      expect(result, isA<ApiFailure<Map<String, dynamic>>>());
      final failure = result as ApiFailure<Map<String, dynamic>>;
      expect(failure.message, contains('Invalid JSON'));
    });
  });
}

class _SampleItem {
  const _SampleItem({required this.id, required this.title});

  final String id;
  final String title;

  factory _SampleItem.fromJson(Map<String, dynamic> json) {
    return _SampleItem(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }
}

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    final bytes = Uint8List.fromList(value.codeUnits);
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _assets[key];
    if (value == null) {
      throw FlutterError('Unable to load asset: $key');
    }
    return value;
  }
}
