import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
// REMOVED: import 'package:flutter_timezone/flutter_timezone.dart'; << We don't need this anymore!

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String channelId = 'nutri_recom_channel';
  static const String channelName = 'NutriRecom Notifications';

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

Future<void> initialize() async {
    try {
      // 1. Initialize the database
      tzdata.initializeTimeZones();

      // 2. THE SHORTCUT: Hardcode Finland Time 🇫🇮
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Helsinki'));
        print('Timezone force-set to Europe/Helsinki');
      } catch (e) {
        print('Could not set Helsinki time: $e');
        // Fallback to UTC so the app DOES NOT CRASH
        try {
            tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (z) {
            print('Even UTC failed. Timezone database might be empty.');
        }
      }

      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings darwinInitializationSettings =
          DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: darwinInitializationSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      await _createNotificationChannel();
    } catch (e) {
      // CRITICAL: If anything goes wrong, log it but DON'T stop the app
      print('Notification Service Initialization Failed: $e');
    }
  }

  /// Explicitly requests notification permissions for Android 13+
  Future<void> requestPermissions() async {
    // Check if the permission handler plugin is properly imported at the top!
    // import 'package:permission_handler/permission_handler.dart';
    
    var status = await Permission.notification.status;
    if (status.isDenied) {
      status = await Permission.notification.request();
    }
    
    if (status.isPermanentlyDenied) {
      // Optional: Open settings if the user previously said "Don't ask again"
      openAppSettings();
    }
    print("Notification Permission Status: $status");
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Notifications for NutriRecom app',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationResponse(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleUnfinishedBatchNotification() async {
    try {
      // Use the Oulu time we set above
      final now = tz.TZDateTime.now(tz.local);
      
      final scheduledTime = now.add(const Duration(hours: 3)); 

      final vibrationPattern = Int64List(4)..[0] = 0..[1] = 500..[2] = 250..[3] = 500;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'NutriRecom',
        'You have unrated meals! Finish them to get new recommendations.',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: vibrationPattern,
          ),
          iOS: const DarwinNotificationDetails(
            sound: 'default.caf',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print('Scheduled unfinished batch for $scheduledTime');
    } catch (e) {
      print('Error scheduling unfinished batch: $e');
    }
  }

  Future<void> scheduleBatchCompleteNotification() async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      
      // Schedule for 6:00 PM (18:00) Oulu time
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        18, 
        0,
      );

      // If it's already past 6 PM, schedule for tomorrow
      if (now.isAfter(scheduledTime)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final vibrationPattern = Int64List(4)..[0] = 0..[1] = 500..[2] = 250..[3] = 500;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        2,
        'NutriRecom',
        'Ready for more? Get your new daily meal plan.',
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: vibrationPattern,
          ),
          iOS: const DarwinNotificationDetails(
            sound: 'default.caf',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print('Scheduled batch complete for $scheduledTime');
    } catch (e) {
      print('Error scheduling batch complete: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}