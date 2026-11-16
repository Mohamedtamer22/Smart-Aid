import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.read,
    required this.createdAt,
  });
  final String id;
  final String type;
  final bool read;
  final DateTime createdAt;
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        read: json['read'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  static List<AppNotification>? _cachedNotifications;

  static final List<AppNotification> _defaultNotifications = [
    AppNotification(
      id: 'notif-01',
      type: 'ACCOUNT_VERIFIED',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'notif-02',
      type: 'DISPATCH_CONFIRMED',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AppNotification(
      id: 'notif-03',
      type: 'SYSTEM_READY',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  List<AppNotification> cachedOrFallbackNotifications() =>
      _cachedNotifications ?? _defaultNotifications;

  Future<List<AppNotification>> all() async {
    try {
      final r = await _api.get<List<dynamic>>('/api/notifications');
      final list = r.data!
          .cast<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
      _cachedNotifications = list;
      return list;
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (failure.isNetworkError) {
        return cachedOrFallbackNotifications();
      }
      throw failure;
    }
  }

  Future<void> markRead(String id) async {
    final current = _cachedNotifications ?? [..._defaultNotifications];
    final index = current.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final old = current[index];
      current[index] = AppNotification(
        id: old.id,
        type: old.type,
        read: true,
        createdAt: old.createdAt,
      );
      _cachedNotifications = current;
    }
    try {
      await _api.patch<Map<String, dynamic>>('/api/notifications/$id/read');
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (!failure.isNetworkError) throw failure;
    }
  }
}
