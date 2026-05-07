import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotification {
  static const String channel_id = "nmobile_d_chat";
  static const String channel_name = "D-Chat";
  static const String channel_desc = "D-Chat notification";

  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  LocalNotification();

  init() async {
    var initializationSettingsAndroid = new AndroidInitializationSettings(
      '@mipmap/ic_launcher_round',
    );
    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: false,
      defaultPresentBadge: true,
    );

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) async {
      _flutterLocalNotificationsPlugin.cancelAll();
    });
  }

  Future show(
    String uuid,
    String title,
    String content, {
    String? targetId,
    int? badgeNumber,
    String? payload,
  }) async {
    // Push notifications removed - local notifications disabled
  }
}
