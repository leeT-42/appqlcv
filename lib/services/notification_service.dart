import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    tz.initializeTimeZones();
    // Đặc biệt fix lỗi timezone VN hoặc các máy trả về '+07', dùng Asia/Ho_Chi_Minh cho ổn định
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Nhắc tới giờ công việc',
      importance: Importance.max,
    );
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Android 13+ runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    // iOS permissions
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _initialized = true;
  }

  int computeIdFromString(String input) {
    // Simple stable hash
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash * 31 + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  Future<void> scheduleTaskReminder({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    await initialize();
    final notifId = computeIdFromString(id);
    final tzTime = tz.TZDateTime.from(dateTime, tz.local);
    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Nhắc tới giờ công việc',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelByIdString(String id) async {
    await initialize();
    await _plugin.cancel(computeIdFromString(id));
  }
}


