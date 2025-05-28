import 'package:flutter/material.dart';
import 'dart:convert';
import 'notification_service.dart';

class PushNotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    print('Push notification service initialized');
    _initialized = true;
  }

  static Future<void> sendProductNotification({
    required String productName,
    required String category,
    required String sellerId,
  }) async {
    // Add to notification list
    await NotificationService.addNotification(
      'New product "$productName" added in $category category by seller',
      sellerId: sellerId,
    );

    print(
        'Would send push notification for new product: $productName in $category');

    final notificationData = {
      'type': 'new_product',
      'product_name': productName,
      'category': category,
      'seller_id': sellerId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('Notification data: ${json.encode(notificationData)}');
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Add to notification list
    await NotificationService.addNotification('$title: $body');

    print('Local notification: $title - $body');

    if (data != null) {
      print('Notification data: ${json.encode(data)}');
    }
  }

  static void showInAppNotification(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notification_important, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Show a custom overlay notification that looks like a real push notification
  static void showPushNotificationOverlay(
    BuildContext context, {
    required String title,
    required String body,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => overlayEntry.remove(),
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
