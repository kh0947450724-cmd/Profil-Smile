import 'dart:convert';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? type;
  final int? orderId;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.orderId,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'order_id': orderId,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString(),
      orderId: json['order_id'] is int
          ? json['order_id']
          : int.tryParse(json['order_id']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }

  factory AppNotification.fromRemoteMessage(Map<String, dynamic> message) {
    final data = message['data'] is Map
        ? Map<String, dynamic>.from(message['data'])
        : <String, dynamic>{};

    final notification = message['notification'] is Map
        ? Map<String, dynamic>.from(message['notification'])
        : <String, dynamic>{};

    return AppNotification(
      id:
          message['messageId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification['title']?.toString() ?? '',
      body: notification['body']?.toString() ?? '',
      type: data['type']?.toString(),
      orderId: int.tryParse(data['order_id']?.toString() ?? ''),
      createdAt: DateTime.now(),
      isRead: false,
      data: data,
    );
  }

  static String encodeList(List<AppNotification> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<AppNotification> decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
