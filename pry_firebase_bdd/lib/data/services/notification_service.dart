import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'chat_messages',
    'Mensajes del chat',
    description: 'Notificaciones de mensajes nuevos',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);

    await _guardarToken();

    _messaging.onTokenRefresh.listen((token) async {
      await _guardarTokenEspecifico(token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await mostrarNotificacion(message);
    });
  }

  static Future<void> _guardarToken() async {
    final token = await _messaging.getToken();

    if (token != null) {
      await _guardarTokenEspecifico(token);
    }
  }

  static Future<void> _guardarTokenEspecifico(String token) async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return;
    }

    await FirebaseDatabase.instance
        .ref('tokens/${usuario.uid}')
        .set({
      'token': token,
      'actualizadoEn': ServerValue.timestamp,
    });

    print('Token FCM guardado: $token');
  }

  static Future<void> mostrarNotificacion(
    RemoteMessage message,
  ) async {
    final notification = message.notification;

    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: notification.title ?? 'Nuevo mensaje',
      body: notification.body ?? 'Tienes un mensaje nuevo',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Mensajes del chat',
          channelDescription: 'Notificaciones de mensajes nuevos',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: 'chat_general',
    );
  }
}