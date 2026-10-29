/// Pure formatting utilities for Indonesian Rupiah (IDR) and timestamps.
class AppFormatters {
  AppFormatters._();

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
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  /// Formats DateTime into short time "13:15 WIB".
  static String formatTimeOnly(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  /// Formats DateTime into Indonesian full date "23 Oktober 2026".
  static String formatFullDate(DateTime dt) {
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
    return '${dt.day} ${fullMonths[dt.month - 1]} ${dt.year}';
  }

  /// Formats DateTime into "23 Oktober 2026 12:00:00 WIB".
  static String formatFullDateTimeWib(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '${formatFullDate(dt)} $hour:$minute:$second WIB';
  }
}
