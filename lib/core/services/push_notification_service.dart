import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Professional Cloud Messaging Service (FCM).
/// Architected for SaaS-level reliability and high-availability spiritual nudges.
class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request Permissions (Critical for iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: Professional access granted.');
    } else {
      debugPrint('FCM: Access denied or restricted.');
    }

    // 2. Handle Foreground Messages (App is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM: Foreground message received: ${message.notification?.title}');
      
      // Pass-through to local NotificationService for UI display
      if (message.notification != null) {
        NotificationService.show(
          id: message.hashCode,
          title: message.notification!.title ?? 'Amal Tracker',
          body: message.notification!.body ?? '',
        );
      }
    });

    // 3. Handle App Opened via Notification (Background/Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: App opened via notification: ${message.notification?.title}');
      // Logic for deep-linking to specific Amal or Analytics could go here
    });

    // 4. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Token Management (For server-side targeting)
    try {
      String? token = await _fcm.getToken();
      debugPrint('FCM Token: $token');
      // In a real SaaS, we would sync this to the Supabase 'profiles' table
    } catch (e) {
      debugPrint('FCM Token Error: $e');
    }
  }

  /// Global static handler for background messages.
  /// Must be top-level or static to run in a separate isolate.
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Note: No UI code here. Only data sync or local notification triggers.
    debugPrint('FCM: Background message received: ${message.messageId}');
  }

  /// Subscribe to global topics (e.g., Foundation Announcements).
  static Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }
}
