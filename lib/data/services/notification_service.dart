// lib/data/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // Đã sửa: Sử dụng named parameter 'settings'
    await _plugin.initialize(
      settings: initSettings,
    );
  }

  Future<void> syncRemindersFromFirestore(String uid) async {
    await _plugin.cancelAll();

    try {
      final snap = await _db
          .collection('reminders')
          .where('user_id', isEqualTo: uid)
          .where('is_active', isEqualTo: true)
          .get();

      int notificationId = 100;

      for (final doc in snap.docs) {
        final data = doc.data();
        final type = data['type'] as String? ?? 'Unknown';
        final message = data['message'] as String? ?? 'Đến giờ rồi!';
        final timeStr = data['reminder_time'] as String? ?? '00:00';

        final parts = timeStr.split(':');
        if (parts.length != 2) continue;

        final time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );

        String title = 'Thông báo Health4U';
        if (type.contains('Breakfast')) {
          title = 'Bữa sáng';
        } else if (type.contains('Lunch')) {
          title = 'Bữa trưa';
        } else if (type.contains('Dinner')) {
          title = 'Bữa tối';
        } else if (type.contains('Snack')) {
          title = 'Bữa phụ';
        } else if (type == 'Water') {
          title = 'Nhắc nhở uống nước 💧';
        }

        await _scheduleDaily(
          id: notificationId,
          title: title,
          body: message,
          time: time,
        );

        notificationId++;
      }
    } catch (e) {
      debugPrint("Lỗi đồng bộ nhắc nhở: $e");
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'health4u_reminders_channel',
          'Nhắc nhở Health4U',
          channelDescription: 'Nhắc nhở lịch ăn uống và tập luyện',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}