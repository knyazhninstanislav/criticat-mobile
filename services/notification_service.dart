import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final Set<int> _sentNotificationIds = {};
  int _notificationCounter = 0;

  // Сигнал для обработки кликов
  final StreamController<NotificationResponse> _onNotificationTap =
      StreamController<NotificationResponse>.broadcast();
  Stream<NotificationResponse> get onNotificationTap =>
      _onNotificationTap.stream;

  Future<void> init() async {
    if (_initialized) return;

    // Инициализация timezone
    tz.initializeTimeZones();

    // Настройки для Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки для iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          _onNotificationTap.add(response);
          _handleNotificationTap(response);
        },
        onDidReceiveBackgroundNotificationResponse: (response) {
          _handleNotificationTap(response);
        },
      );

      // Запрос разрешений для iOS
      await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Запрос разрешений для Android (важно для API 33+)
      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();

      _initialized = true;
      print('✅ NotificationService инициализирован');
    } catch (e) {
      print('❌ Ошибка инициализации NotificationService: $e');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('📱 Уведомление нажато: ${response.payload}');
    // Здесь можно добавить навигацию
    if (response.payload?.startsWith('result_') ?? false) {
      final resultId = int.tryParse(response.payload!.replaceFirst('result_', ''));
      if (resultId != null) {
        // Можно открыть детали результата
        print('🔍 Открыть результат #$resultId');
      }
    }
  }

  // ===== ОСНОВНЫЕ МЕТОДЫ =====

  Future<bool> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    int? millisecondsDelay,
  }) async {
    if (!_initialized) {
      await init();
    }

    try {
      // Проверяем дубликаты (не отправляем одно и то же уведомление)
      final key = '$title|$body';
      if (_sentNotificationIds.contains(id)) {
        print('⚠️ Уведомление #$id уже отправлено');
        return false;
      }

      // Android настройки
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'critical_results',
        'Критические результаты',
        channelDescription:
            'Уведомления о критических отклонениях в лабораторных исследованиях',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        showWhen: true,
        ticker: 'Критическое отклонение!',
        visibility: NotificationVisibility.public,
        color: const Color(0xFFFF2D55),
        ledColor: const Color(0xFFFF2D55),
        ledOnMs: 1000,
        ledOffMs: 500,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          htmlFormatBigText: false,
        ),
      );

      // iOS настройки
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'critical_result',
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Отправляем уведомление
      if (millisecondsDelay != null && millisecondsDelay > 0) {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.now(tz.local).add(Duration(milliseconds: millisecondsDelay)),
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exact,
        );
      } else {
        await _notifications.show(id, title, body, details, payload: payload);
      }

      // Запоминаем отправленное
      _sentNotificationIds.add(id);
      _notificationCounter++;

      print('✅ Уведомление показано: $title');
      return true;
    } catch (e) {
      print('❌ Ошибка показа уведомления: $e');
      return false;
    }
  }

  // ===== СПЕЦИАЛЬНЫЕ УВЕДОМЛЕНИЯ =====

  Future<bool> showCriticalResultNotification({
    required int resultId,
    required String testName,
    required double value,
    String? department,
    String? patientName,
  }) async {
    final title = '🚨 КРИТИЧЕСКОЕ ОТКЛОНЕНИЕ!';

    String body;
    if (patientName != null && patientName.isNotEmpty) {
      body = '$patientName: $testName = $value';
    } else {
      body = '$testName: $value';
    }

    if (department != null && department.isNotEmpty) {
      body += '\n📋 $department';
    }

    final id = 1000 + resultId; // Уникальный ID для результатов

    return showNotification(
      id: id,
      title: title,
      body: body,
      payload: 'result_$resultId',
    );
  }

  Future<bool> showMultipleResultsNotification({
    required int count,
    required String department,
  }) async {
    final id = 2000 + DateTime.now().millisecondsSinceEpoch % 10000;

    return showNotification(
      id: id,
      title: '🚨 МНОЖЕСТВЕННЫЕ ОТКЛОНЕНИЯ!',
      body: 'Обнаружено $count критических результатов\n📋 $department',
      payload: 'multiple_$id',
    );
  }

  Future<bool> showConfirmationNotification({
    required int resultId,
    required bool accepted,
  }) async {
    final id = 3000 + resultId;

    if (accepted) {
      return showNotification(
        id: id,
        title: '✅ РЕЗУЛЬТАТ ПОДТВЕРЖДЕН',
        body: 'Результат #$resultId принят',
        payload: 'confirm_$resultId',
      );
    } else {
      return showNotification(
        id: id,
        title: '❌ РЕЗУЛЬТАТ ОТКЛОНЕН',
        body: 'Результат #$resultId отклонен',
        payload: 'reject_$resultId',
      );
    }
  }

  Future<bool> showConnectionNotification({
    required bool connected,
  }) async {
    final id = 9999;

    if (connected) {
      return showNotification(
        id: id,
        title: '✅ ПОДКЛЮЧЕНО К СЕРВЕРУ',
        body: 'Соединение с MQTT брокером установлено',
        payload: 'connected',
      );
    } else {
      return showNotification(
        id: id,
        title: '⚠️ ПОТЕРЯНО СОЕДИНЕНИЕ',
        body: 'Попытка переподключения...',
        payload: 'disconnected',
      );
    }
  }

  Future<bool> showTestNotification() async {
    final id = 8888;
    return showNotification(
      id: id,
      title: '🔔 Тестовое уведомление',
      body: 'CritiCat работает корректно!',
      payload: 'test',
    );
  }

  // ===== УПРАВЛЕНИЕ УВЕДОМЛЕНИЯМИ =====

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      _sentNotificationIds.remove(id);
      print('🗑️ Уведомление #$id отменено');
    } catch (e) {
      print('❌ Ошибка отмены уведомления: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _sentNotificationIds.clear();
      print('🗑️ Все уведомления отменены');
    } catch (e) {
      print('❌ Ошибка отмены всех уведомлений: $e');
    }
  }

  Future<List<ActiveNotification>> getActiveNotifications() async {
    try {
      return await _notifications.getActiveNotifications();
    } catch (e) {
      print('❌ Ошибка получения уведомлений: $e');
      return [];
    }
  }

  void dispose() {
    _onNotificationTap.close();
  }
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  Future<void> requestPermission() async {}
}