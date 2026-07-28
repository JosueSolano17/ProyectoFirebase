import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/firebase_service.dart';
import '../../domain/models/mensaje.dart';
import '../../domain/models/usuario.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final usuariosProvider = StreamProvider<List<Usuario>>((ref) {
  final service = ref.watch(firebaseServiceProvider);
  return service.obtenerUsuarios();
});

final mensajesProvider = StreamProvider.family<List<Mensaje>, String>((ref, chatId) {
  final service = ref.watch(firebaseServiceProvider);
  return service.recibirMensajes(chatId);
});
