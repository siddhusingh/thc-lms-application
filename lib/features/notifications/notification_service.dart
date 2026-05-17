import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {
      // Firebase configuration is optional for local development.
    }
  }

  Future<String?> getDeviceToken() async {
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> showLocal({
    required int id,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'learning_updates',
        'Learning updates',
        channelDescription: 'Course, assessment, and certificate alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(settings: settings);
  }
}
