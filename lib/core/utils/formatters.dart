/// Pure formatting utilities for Indonesian Rupiah (IDR) and timestamps.
class AppFormatters {
  AppFormatters._();

  /// Safely parses server timestamp strings (UTC, RFC3339, or ISO-8601) and converts to local timezone (e.g. WIB / UTC+7).
  static DateTime parseServerDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    final raw = value.toString().trim();
    if (raw.isEmpty) return DateTime.now();

    DateTime? parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      if (parsed.isUtc) {
        return parsed.toLocal();
      }
      // If the string did not specify a timezone offset (e.g. "2026-11-06 01:56:00"),
      // standard backend databases (PostgreSQL/MySQL/Go) store and emit UTC by default.
      if (!raw.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw)) {
        final utcString = '${raw.replaceAll(' ', 'T')}Z';
        final utcParsed = DateTime.tryParse(utcString);
        if (utcParsed != null) {
          return utcParsed.toLocal();
        }
      }
      return parsed.toLocal();
    }
    return DateTime.now();
  }

  /// Formats integer Rupiah value (e.g., 12500 -> "Rp 12.500").
  static String formatRupiah(int amount) {
    final isNegative = amount < 0;
    final digits = amount.abs().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return '${isNegative ? '-Rp ' : 'Rp '}${buffer.toString()}';
  }

  /// Formats DateTime into "13 Okt 2026, 13:15".
  static String formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  /// Formats DateTime into short time "13:15 WIB".
  static String formatTimeOnly(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  /// Formats DateTime into Indonesian full date "23 Oktober 2026".
  static String formatFullDate(DateTime dt) {
    final local = dt.toLocal();
    const fullMonths = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${local.day} ${fullMonths[local.month - 1]} ${local.year}';
  }

  /// Formats DateTime into "23 Oktober 2026 12:00:00 WIB".
  static String formatFullDateTimeWib(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '${formatFullDate(local)} $hour:$minute:$second WIB';
  }
}
