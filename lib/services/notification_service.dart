import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

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
      // Initialize timezone database
      try {
        tzdata.initializeTimeZones();
        print('Timezone database initialized successfully');
      } catch (e) {
        print('Warning: Could not initialize timezone database: $e');
      }
      
      // Detect and set device's actual timezone using flutter_timezone
      try {
        final timezoneData = await FlutterTimezone.getLocalTimezone();
        // TimezoneInfo.toString() returns: "TimezoneInfo(Europe/Kiev, (locale: en_US, name: ...))"
        // We need to extract just the timezone ID (Europe/Kiev)
        final String timezoneName = timezoneData.toString().split('(')[1].split(',')[0];
        tz.setLocalLocation(tz.getLocation(timezoneName));
        print('✅ Device timezone detected: $timezoneName (${tz.local.name})');
      } catch (e) {
        print('⚠️ Could not detect device timezone: $e');
        print('Falling back to UTC');
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
          print('⚠️ Using UTC as fallback');
        } catch (fallbackError) {
          print('❌ Error setting UTC fallback: $fallbackError');
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

      // Request notification permission for Android 13+
      await requestPermissions();
      
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
      // Use device's current time in local timezone
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(hours: 3));
      
      print('Current time (local): $now');
      print('Scheduling notification for: $scheduledTime');

      // Check if we already showed this notification recently
      final prefs = await SharedPreferences.getInstance();
      final lastShownTime = prefs.getInt('last_unfinished_notification_time') ?? 0;
      final timeSinceLastNotification = now.millisecondsSinceEpoch - lastShownTime;
      final threeHoursMs = 3 * 60 * 60 * 1000;

      // Only show if 3 hours have passed since last notification
      if (timeSinceLastNotification >= threeHoursMs) {
        // Show notification immediately when app is minimized
        await _flutterLocalNotificationsPlugin.show(
          1,
          'NutriRecom',
          'You have unrated meals! Finish them to get new recommendations.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              vibrationPattern: Int64List(4)..[0] = 0..[1] = 500..[2] = 250..[3] = 500,
            ),
            iOS: const DarwinNotificationDetails(
              sound: 'default.caf',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
        
        // Save the time we showed this notification
        await prefs.setInt('last_unfinished_notification_time', now.millisecondsSinceEpoch);
        print('✅ Successfully sent unfinished batch notification');
      } else {
        final minutesUntilNextNotification = (threeHoursMs - timeSinceLastNotification) ~/ 60000;
        print('⏭️ Notification cooldown: ready again in $minutesUntilNextNotification minutes');
      }
    } catch (e) {
      print('Error sending unfinished batch notification: $e');
    }
  }

  Future<void> scheduleBatchCompleteNotification() async {
    try {
      // Use device's current time in local timezone
      final now = tz.TZDateTime.now(tz.local);
      
      // Calculate when 6:00 PM is
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        18,  // 6:00 PM
        0,
      );

      // If it's already past 6 PM today, schedule for tomorrow
      if (now.isAfter(scheduledTime)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      print('Current time (local): $now');
      print('6:00 PM scheduled time: $scheduledTime');
      
      // Check if we already showed this notification today
      final prefs = await SharedPreferences.getInstance();
      final lastShownTime = prefs.getInt('last_batch_complete_notification_time') ?? 0;
      
      // Get today's date at 6 PM for comparison
      final todayAt6PM = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        18,
        0,
      );
      
      // If 6 PM hasn't occurred yet today, don't show the notification
      if (now.isBefore(todayAt6PM)) {
        print('⏭️ It is not yet 6:00 PM - notification scheduled to show at 6:00 PM');
        return;
      }
      
      // Get today's date at midnight for checking if we showed this today
      final todayAtMidnight = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        0,
        0,
      );
      
      // Only show if we haven't already shown this notification today
      if (lastShownTime < todayAtMidnight.millisecondsSinceEpoch) {
        // Show notification immediately when app is minimized at or after 6 PM
        await _flutterLocalNotificationsPlugin.show(
          2,
          'NutriRecom',
          'Ready for more? Get your new daily meal plan.',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              vibrationPattern: Int64List(4)..[0] = 0..[1] = 500..[2] = 250..[3] = 500,
            ),
            iOS: const DarwinNotificationDetails(
              sound: 'default.caf',
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
        
        // Save the time we showed this notification
        await prefs.setInt('last_batch_complete_notification_time', now.millisecondsSinceEpoch);
        print('✅ Successfully sent batch complete notification');
      } else {
        print('⏭️ Batch complete notification already shown today - will be ready tomorrow at 6:00 PM');
      }
    } catch (e) {
      print('Error sending batch complete notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}