// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  static Future<void> showPredictionNotification(
    String title,
    String body,
    bool isPregnant,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'prediction_channel',
          'Predições de Prenhez',
          channelDescription:
              'Notificações sobre resultados de predição de prenhez',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.green,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  static Future<void> scheduleReminderNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'reminder_channel',
          'Lembretes',
          channelDescription: 'Lembretes para verificação de vacas',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Corrigido: Parâmetro 'androidScheduleMode' adicionado para resolver o erro de compilação.
    await _notifications.periodicallyShow(
      0,
      'Lembrete de Verificação',
      'Não se esqueça de verificar as vacas hoje!',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
