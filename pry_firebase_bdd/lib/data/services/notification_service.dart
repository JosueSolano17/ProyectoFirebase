import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'chat_messages',
    'Mensajes del chat',
    description: 'Notificaciones de nuevos mensajes del chat',
    importance: Importance.high,
  );

  Future<void> inicializar() async {
    await _solicitarPermisos();
    await _configurarNotificacionesLocales();
    await _configurarMensajes();
  }

  Future<void> _solicitarPermisos() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print(
      'Permiso de notificaciones: '
      '${settings.authorizationStatus}',
    );
  }

  Future<void> _configurarNotificacionesLocales() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notificación pulsada: ${response.payload}');
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);
  }

  Future<void> _configurarMensajes() async {
    // Para mostrar notificaciones mientras la aplicación está abierta.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _mostrarNotificacion(message);
    });

    // Se ejecuta cuando el usuario abre una notificación.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación abierta: ${message.data}');
    });

    // Configuración para iOS.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> guardarTokenDelUsuario() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No se guardó el token porque no existe usuario autenticado.');
      return;
    }

    final token = await _messaging.getToken();

    if (token == null) {
      print('Firebase Messaging no generó un token.');
      return;
    }

    await FirebaseDatabase.instance.ref('tokens/${user.uid}').set({
      'token': token,
      'updatedAt': ServerValue.timestamp,
    });

    print('Token FCM guardado para ${user.uid}');
    print(token);

    // Actualizar el token cuando Firebase lo cambie.
    _messaging.onTokenRefresh.listen((nuevoToken) async {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return;
      }

      await FirebaseDatabase.instance.ref('tokens/${currentUser.uid}').set({
        'token': nuevoToken,
        'updatedAt': ServerValue.timestamp,
      });

      print('Token FCM actualizado.');
    });
  }

  Future<void> _mostrarNotificacion(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) {
      return;
    }

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'Nuevo mensaje',
      body: notification.body ?? '',
      notificationDetails: notificationDetails,
      payload: message.data['chatId'],
    );
  }
}
