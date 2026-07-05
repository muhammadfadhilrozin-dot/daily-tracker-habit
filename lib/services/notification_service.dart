import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Mengelola penjadwalan notifikasi lokal untuk reminder tiap habit.
/// Tiap habit memakai id notifikasi = id habit, supaya mudah update/cancel.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);

    // Minta izin notifikasi (wajib untuk Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Jadwalkan reminder harian berulang untuk satu habit pada jam:menit tertentu
  Future<void> scheduleHabitReminder({
    required int habitId,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: habitId,
      title: 'Waktunya: $habitName',
      body: 'Jangan lupa selesaikan habit-mu hari ini 💪',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminder_channel',
          'Pengingat Habit',
          channelDescription:
              'Notifikasi pengingat untuk menyelesaikan habit harian',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // ulang setiap hari di jam yang sama
    );
  }

  Future<void> cancelHabitReminder(int habitId) async {
    await init();
    await _plugin.cancel(id: habitId);
  }
}
