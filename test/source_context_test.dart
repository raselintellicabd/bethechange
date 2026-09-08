import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SourceContext', () {
    test('encodes and parses round-trip', () {
      const original = SourceContext(
        type: SourceContextType.condition,
        id: 'diabetes',
        name: 'Diabetes',
      );

      final parsed = SourceContext.tryParse(original.encode());

      expect(parsed, original);
      expect(parsed?.type, SourceContextType.condition);
      expect(parsed?.id, 'diabetes');
      expect(parsed?.name, 'Diabetes');
    });

    test('tryParse returns null for missing or invalid payloads', () {
      expect(SourceContext.tryParse(null), isNull);
      expect(SourceContext.tryParse(''), isNull);
      expect(SourceContext.tryParse('not-json'), isNull);
      expect(SourceContext.tryParse('{"type":"condition","id":"","name":"X"}'), isNull);
      expect(
        SourceContext.tryParse('{"type":"unknown","id":"a","name":"A"}'),
        isNull,
      );
    });

    test('other type allows empty id', () {
      const context = SourceContext(
        type: SourceContextType.other,
        id: '',
        name: 'General Booking',
      );

      expect(SourceContext.tryParse(context.encode()), context);
    });

    test('appointmentPath includes encoded sourceContext query', () {
      const context = SourceContext(
        type: SourceContextType.service,
        id: 'frequency-specific-microcurrent',
        name: 'Frequency Specific Microcurrent Therapy',
      );

      final path = AppRoutes.appointmentPath(context);
      final uri = Uri.parse(path);

      expect(uri.path, AppRoutes.appointment);
      expect(
        SourceContext.tryParse(uri.queryParameters['sourceContext']),
        context,
      );
    });
  });
}
