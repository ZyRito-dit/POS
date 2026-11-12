import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';

/// DTO for single notification item from KatoPOS Backend API (`/api/v1/notifications`).
class NotificationItemDto {
  final int id;
  final String title;
  final String message;
  final String? type;
  final String? referenceType;
  final int? referenceId;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  const NotificationItemDto({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationItemDto.fromJson(Map<String, dynamic> json) {
    return NotificationItemDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Notifikasi',
      message: json['message'] as String? ?? '',
      type: json['type'] as String?,
      referenceType: json['reference_type'] as String?,
      referenceId: (json['reference_id'] as num?)?.toInt(),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  SystemNotification toEntity() {
    NotificationSeverity severity = NotificationSeverity.info;
    final upperType = (type ?? '').toUpperCase();
    if (upperType.contains('SUCCESS') || upperType.contains('PAYMENT')) {
      severity = NotificationSeverity.success;
    } else if (upperType.contains('WARN') ||
        upperType.contains('STOCK') ||
        upperType.contains('ALERT')) {
      severity = NotificationSeverity.warning;
    } else if (upperType.contains('ERROR') ||
        upperType.contains('FAIL') ||
        upperType.contains('CANCEL')) {
      severity = NotificationSeverity.error;
    }

    final parsedCreatedAt =
        AppFormatters.parseServerDateTime(createdAt);
    final parsedReadAt =
        readAt != null ? AppFormatters.parseServerDateTime(readAt!) : null;

    return SystemNotification(
      id: id,
      title: title,
      message: message,
      createdAt: parsedCreatedAt,
      isRead: isRead,
      severity: severity,
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      readAt: parsedReadAt,
    );
  }
}

/// DTO for `/api/v1/notifications` list and unread counter response.
class NotificationListResponseDto {
  final List<NotificationItemDto> items;
  final int unreadCount;

  const NotificationListResponseDto({
    required this.items,
    required this.unreadCount,
  });

  factory NotificationListResponseDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> target = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawItems = target['items'];
    final itemsList = <NotificationItemDto>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          itemsList.add(NotificationItemDto.fromJson(item));
        }
      }
    }

    final count = (target['unread_count'] as num?)?.toInt() ??
        itemsList.where((i) => !i.isRead).length;

    return NotificationListResponseDto(
      items: itemsList,
      unreadCount: count,
    );
  }
}
