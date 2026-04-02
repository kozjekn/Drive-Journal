import 'package:flutter_test/flutter_test.dart';
import 'package:ride_journal/core/utils/format_utils.dart';

void main() {
  group('FormatUtils', () {
    group('formatDistance', () {
      test('formats meters for short distances', () {
        expect(FormatUtils.formatDistance(500), '500 m');
      });

      test('formats kilometers for long distances', () {
        expect(FormatUtils.formatDistance(15230), '15.23 km');
      });

      test('formats zero distance', () {
        expect(FormatUtils.formatDistance(0), '0 m');
      });
    });

    group('formatDuration', () {
      test('formats seconds only', () {
        expect(FormatUtils.formatDuration(const Duration(seconds: 45)), '45s');
      });

      test('formats minutes and seconds', () {
        expect(
          FormatUtils.formatDuration(const Duration(minutes: 5, seconds: 30)),
          '5m 30s',
        );
      });

      test('formats hours, minutes, and seconds', () {
        expect(
          FormatUtils.formatDuration(
            const Duration(hours: 1, minutes: 15, seconds: 0),
          ),
          '1h 15m 0s',
        );
      });
    });

    group('formatSpeed', () {
      test('formats speed with one decimal', () {
        expect(FormatUtils.formatSpeed(45.2), '45.2 km/h');
      });

      test('formats zero speed', () {
        expect(FormatUtils.formatSpeed(0), '0.0 km/h');
      });
    });

    group('formatElevation', () {
      test('formats elevation in meters', () {
        expect(FormatUtils.formatElevation(120.5), '121 m');
      });
    });

    group('formatDateTime', () {
      test('formats date and time', () {
        final dt = DateTime(2025, 3, 15, 14, 30);
        expect(FormatUtils.formatDateTime(dt), 'Mar 15, 2025 14:30');
      });
    });
  });
}
