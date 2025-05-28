// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _notificationsKey = 'notifications';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    print('Notification service initialized');
  }

  static Future<void> addNotification(String message,
      {String? sellerId}) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    List<Map<String, dynamic>> notifications = [];

    if (notificationsJson != null) {
      notifications = (json.decode(notificationsJson) as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    notifications.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
      'sellerId': sellerId,
    });

    await prefs.setString(_notificationsKey, json.encode(notifications));
  }

  static Future<List<Map<String, dynamic>>> getNotifications(
      {String? sellerId}) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson == null) return [];

    List<Map<String, dynamic>> notifications =
        (json.decode(notificationsJson) as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

    if (sellerId != null) {
      return notifications.where((n) => n['sellerId'] == sellerId).toList();
    }

    return notifications;
  }

  static Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);

    if (notificationsJson == null) return;

    List<Map<String, dynamic>> notifications =
        (json.decode(notificationsJson) as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

    final index = notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      notifications[index]['read'] = true;
      await prefs.setString(_notificationsKey, json.encode(notifications));
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Store as in-app notification instead of system notification
    await addNotification('$title: $body');
    print('In-app notification: $title - $body');
  }
}
