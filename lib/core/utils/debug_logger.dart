import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model data untuk satu entri log API debug terminal.
class ApiDebugLogEntry {
  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final Map<String, dynamic>? headers;
  final dynamic requestBody;
  final int? statusCode;
  final int? durationMs;
  final dynamic responseBody;
  final String? errorMessage;
  final String? errorCode;
  final String? errorDetails;
  final bool isSuccess;

  const ApiDebugLogEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    this.headers,
    this.requestBody,
    this.statusCode,
    this.durationMs,
    this.responseBody,
    this.errorMessage,
    this.errorCode,
    this.errorDetails,
    required this.isSuccess,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

/// Service untuk mencatat log API langsung ke Terminal Konsol (debugPrint)
/// dan menyediakan riwayat log untuk inspeksi langsung di UI (debug terminal).
class DebugLogger {
  DebugLogger._();
  static final DebugLogger instance = DebugLogger._();

  final List<ApiDebugLogEntry> _logs = [];
  List<ApiDebugLogEntry> get logs => List.unmodifiable(_logs);

  void Function(ApiDebugLogEntry entry)? onLogAdded;

  void logRequest({
    required String id,
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    final entry = ApiDebugLogEntry(
      id: id,
      timestamp: DateTime.now(),
      method: method,
      url: url,
      headers: headers,
      requestBody: _sanitizePayload(body),
      isSuccess: false,
    );

    _printBox(
      title: 'TERMINAL DEBUG: API REQUEST DIKIRIM',
      colorTag: '>> [MENGIRIM]',
      lines: [
        'Waktu       : ${entry.formattedTime}',
        'Method      : $method',
        'Target URL  : $url',
        if (headers != null && headers.isNotEmpty)
          'Headers     : ${_prettyJson(headers)}',
        'Payload Body: ${_prettyJson(entry.requestBody)}',
        'Status      : Menunggu respon dari server...',
      ],
    );

    _addLog(entry);
  }

  void logSuccess({
    required String id,
    required String method,
    required String url,
    required int statusCode,
    required int durationMs,
    dynamic responseBody,
  }) {
    final entry = ApiDebugLogEntry(
      id: id,
      timestamp: DateTime.now(),
      method: method,
      url: url,
      statusCode: statusCode,
      durationMs: durationMs,
      responseBody: responseBody,
      isSuccess: true,
    );

    _printBox(
      title: 'TERMINAL DEBUG: API RESPON BERHASIL ($statusCode OK)',
      colorTag: '<< [BERHASIL]',
      lines: [
        'Waktu       : ${entry.formattedTime}',
        'Target URL  : $url',
        'Status Code : $statusCode OK',
        'Durasi      : ${durationMs}ms',
        'Response    : ${_prettyJson(responseBody)}',
      ],
    );

    _updateOrAddLog(entry);
  }

  void logError({
    required String id,
    required String method,
    required String url,
    int? statusCode,
    required int durationMs,
    dynamic responseBody,
    required String errorMessage,
    String? errorCode,
    String? errorDetails,
    String? suggestion,
  }) {
    final entry = ApiDebugLogEntry(
      id: id,
      timestamp: DateTime.now(),
      method: method,
      url: url,
      statusCode: statusCode,
      durationMs: durationMs,
      responseBody: responseBody,
      errorMessage: errorMessage,
      errorCode: errorCode,
      errorDetails: errorDetails,
      isSuccess: false,
    );

    _printBox(
      title: 'TERMINAL DEBUG: API RESPON GAGAL / ERROR',
      colorTag: '!! [GAGAL]',
      lines: [
        'Waktu       : ${entry.formattedTime}',
        'Target URL  : $url',
        'Status Code : ${statusCode != null ? "$statusCode" : "Tidak ada respon / Connection Error"}',
        'Durasi      : ${durationMs}ms',
        'Pesan Error : $errorMessage',
        if (errorCode != null) 'Kode Error  : $errorCode',
        if (errorDetails != null) 'Detail Error: $errorDetails',
        if (responseBody != null) 'Raw Response: ${_prettyJson(responseBody)}',
        if (suggestion != null) 'Saran Solusi: $suggestion',
      ],
    );

    _updateOrAddLog(entry);
  }

  void _addLog(ApiDebugLogEntry entry) {
    _logs.insert(0, entry);
    if (_logs.length > 50) _logs.removeLast();
    onLogAdded?.call(entry);
  }

  void _updateOrAddLog(ApiDebugLogEntry entry) {
    final idx = _logs.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _logs[idx] = entry;
      onLogAdded?.call(entry);
    } else {
      _addLog(entry);
    }
  }

  void clearLogs() {
    _logs.clear();
  }

  void _printBox({
    required String title,
    required String colorTag,
    required List<String> lines,
  }) {
    const separator = '================================================================================';
    final sb = StringBuffer();
    sb.writeln('\n$separator');
    sb.writeln('[$colorTag] $title');
    sb.writeln('--------------------------------------------------------------------------------');
    for (final line in lines) {
      sb.writeln('  $line');
    }
    sb.writeln('$separator\n');
    debugPrint(sb.toString());
  }

  dynamic _sanitizePayload(dynamic body) {
    if (body is Map) {
      final sanitized = Map<String, dynamic>.from(body);
      if (sanitized.containsKey('password')) {
        final pwd = sanitized['password'].toString();
        sanitized['password'] = '****** (${pwd.length} karakter)';
      }
      return sanitized;
    }
    return body;
  }

  String _prettyJson(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is String) return data;
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}

/// State notifier untuk menyajikan log debug API ke widget UI.
class ApiDebugLogNotifier extends StateNotifier<List<ApiDebugLogEntry>> {
  ApiDebugLogNotifier() : super(DebugLogger.instance.logs) {
    DebugLogger.instance.onLogAdded = (entry) {
      state = List.from(DebugLogger.instance.logs);
    };
  }

  void clear() {
    DebugLogger.instance.clearLogs();
    state = [];
  }
}

final apiDebugLogProvider =
    StateNotifierProvider<ApiDebugLogNotifier, List<ApiDebugLogEntry>>((ref) {
  return ApiDebugLogNotifier();
});

/// Menyediakan entri log terakhir untuk quick inspection
final lastApiDebugLogProvider = Provider<ApiDebugLogEntry?>((ref) {
  final logs = ref.watch(apiDebugLogProvider);
  return logs.isNotEmpty ? logs.first : null;
});
