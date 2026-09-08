import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib does not use uncached Image.network for remote images', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (RegExp(r'Image\.network\s*\(').hasMatch(source)) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use CachedNetworkImage / ImageWithCaption instead of Image.network. '
          'Found in: $offenders',
    );
  });
}
