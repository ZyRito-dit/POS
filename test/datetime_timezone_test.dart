import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';

void main() {
  group('AppFormatters Timezone Conversion Tests', () {
    test('UTC ISO-8601 string is converted to local device time correctly', () {
      // 01:56 UTC
      final parsed = AppFormatters.parseServerDateTime('2026-11-06T01:56:00Z');
      expect(parsed.isUtc, isFalse);

      // Verify formatTimeOnly outputs local time
      final timeStr = AppFormatters.formatTimeOnly(parsed);
      final expectedHour = parsed.hour.toString().padLeft(2, '0');
      final expectedMinute = parsed.minute.toString().padLeft(2, '0');
      expect(timeStr, equals('$expectedHour:$expectedMinute WIB'));
    });

    test('Naive server UTC string without Z is parsed and converted to local time', () {
      final parsed = AppFormatters.parseServerDateTime('2026-11-06 01:56:00');
      expect(parsed.isUtc, isFalse);

      final fullDateStr = AppFormatters.formatFullDate(parsed);
      expect(fullDateStr, contains('November 2026'));
    });

    test('formatFullDateTimeWib formats converted local time with full date and seconds', () {
      final parsed = AppFormatters.parseServerDateTime('2026-11-06T01:56:30Z');
      final fullStr = AppFormatters.formatFullDateTimeWib(parsed);
      final expectedHour = parsed.hour.toString().padLeft(2, '0');
      expect(fullStr, contains('$expectedHour:56:30 WIB'));
    });

    test('formatNotificationDateTime formats relative day and WIB timezone correctly', () {
      final now = DateTime.now();
      final todayFormatted = AppFormatters.formatNotificationDateTime(now);
      expect(todayFormatted, startsWith('Hari ini, '));
      expect(todayFormatted, endsWith(' WIB'));

      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayFormatted = AppFormatters.formatNotificationDateTime(yesterday);
      expect(yesterdayFormatted, startsWith('Kemarin, '));
      expect(yesterdayFormatted, endsWith(' WIB'));

      final pastDate = DateTime(2026, 11, 4, 10, 30);
      final pastFormatted = AppFormatters.formatNotificationDateTime(pastDate);
      expect(pastFormatted, equals('04 Nov 2026, 10:30 WIB'));
    });
  });
}
