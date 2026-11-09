import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/meal_type.dart';
import '../repositories/settings_repository.dart';

/// 끼니 기록 알림 예약.
abstract interface class ReminderService {
  /// 알림 권한을 묻는다. 허용하면 true.
  Future<bool> requestPermission();

  /// 켜진 알림만 매일 반복으로 다시 예약한다.
  Future<void> apply(List<MealReminder> reminders);
}

/// 기기 로컬 알림 구현
class LocalReminderService implements ReminderService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'meal_reminders',
      '끼니 알림',
      channelDescription: '끼니 시간에 식사 기록을 알려드려요',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  @override
  Future<void> apply(List<MealReminder> reminders) async {
    await _init();
    for (final (i, r) in reminders.indexed) {
      await _plugin.cancel(id: i + 1);
      if (!r.enabled) continue;
      await _plugin.zonedSchedule(
        id: i + 1,
        title: reminderTitle(r.mealType),
        body: '사진 한 장이면 기록 끝! 지금 바로 남겨보세요',
        scheduledDate: _next(r.hour, r.minute),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }
}

String reminderTitle(String mealType) => switch (mealType) {
  MealType.breakfast => '좋은 아침이에요! 아침 드셨나요?',
  MealType.lunch => '점심 맛있게 드셨나요?',
  MealType.dinner => '오늘 저녁은 뭐 드셨어요?',
  _ => '오늘 먹은 걸 기록해볼까요?',
};
