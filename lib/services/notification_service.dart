import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  // Legacy channel — kept so existing installs don't break; no longer posted to.
  static const String channelId = 'nutri_recom_channel';
  static const String channelName = 'NutriRecom Notifications';

  // Silent channel — used for all notifications (won't wake users at night).
  static const String silentChannelId = 'nutri_recom_silent_channel';
  static const String silentChannelName = 'NutriRecom Silent Notifications';

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
        // getLocalTimezone() returns TimezoneInfo; .identifier is the IANA string e.g. "Europe/Helsinki"
        final String timezoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
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

      await _createNotificationChannels();
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

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Legacy high-importance channel — kept so existing installs aren't broken.
    // No longer posted to; all new notifications use the silent channel below.
    const AndroidNotificationChannel legacyChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Notifications for NutriRecom app (legacy)',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );
    await androidPlugin?.createNotificationChannel(legacyChannel);

    // Silent channel — appears in notification shade with no sound or vibration.
    const AndroidNotificationChannel silentChannel = AndroidNotificationChannel(
      silentChannelId,
      silentChannelName,
      description: 'Silent notifications for NutriRecom app',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );
    await androidPlugin?.createNotificationChannel(silentChannel);
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
        // Show notification silently when app is minimized
        await _flutterLocalNotificationsPlugin.show(
          1,
          'NutriRecom',
          'You have unrated meals! Finish them to get new recommendations.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              silentChannelId,
              silentChannelName,
              importance: Importance.low,
              priority: Priority.low,
              playSound: false,
              enableVibration: false,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: false,
              presentSound: false,
            ),
          ),
        );

        // Save the time we showed this notification
        await prefs.setInt('last_unfinished_notification_time', now.millisecondsSinceEpoch);
        print('✅ Successfully sent unfinished batch notification (silent)');
      } else {
        final minutesUntilNextNotification = (threeHoursMs - timeSinceLastNotification) ~/ 60000;
        print('⏭️ Notification cooldown: ready again in $minutesUntilNextNotification minutes');
      }
    } catch (e) {
      print('Error sending unfinished batch notification: $e');
    }
  }

  /// Schedules a silent notification to fire at exactly [scheduledTime] —
  /// the moment the next batch of recommendations becomes available.
  /// Cancels any previously pending "ready" notification first.
  Future<void> scheduleRecommendationsReadyNotification(DateTime scheduledTime) async {
    try {
      if (!scheduledTime.isAfter(DateTime.now())) {
        print('⏭️ Scheduled time is already past — skipping ready notification');
        return;
      }

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime.toUtc(), tz.UTC);

      print('Scheduling "ready" notification for: $tzScheduledTime');

      // Cancel any previously scheduled ready notification before re-scheduling.
      await _flutterLocalNotificationsPlugin.cancel(2);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        2,
        'NutriRecom',
        'Your new meal recommendations are ready! Open the app to see them.',
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            silentChannelId,
            silentChannelName,
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ "Ready" notification scheduled silently for $tzScheduledTime');
    } catch (e) {
      print('Error scheduling recommendations ready notification: $e');
    }
  }

  /// Cancels only the "unrated meals" notification (ID=1).
  /// Does NOT cancel the scheduled "ready" alarm (ID=2) — that must survive
  /// app resume so it can still fire when the app is closed/minimized.
  Future<void> cancelUnratedMealsNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(1);
  }

  /// Cancels every pending notification including the scheduled alarm.
  /// Only call this when the experiment is complete or on logout.
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}