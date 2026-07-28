import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/views/home_view.dart';
import 'presentation/views/login_view.dart';
import 'data/services/notification_service.dart';
import 'themes/tema_app_mensajeria.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Mensaje recibido en segundo plano: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.inicializar();
  // Se guardara el token solo si hay usuario logueado en la view principal
  await NotificationService.instance.guardarTokenDelUsuario();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Chat Firebase',
      debugShowCheckedModeBanner: false,
      theme: TemaAppMensajeria.obtenerTema(),
      home: authStateAsync.when(
        data: (user) {
          if (user != null) {
            // Guardamos o actualizamos token FCM cuando inicia sesión.
            NotificationService.instance.guardarTokenDelUsuario();
            return const HomeView();
          }
          return const LoginView();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
