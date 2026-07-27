import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/firebase_service.dart';
import '../../domain/models/mensaje.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final mensajesProvider = StreamProvider<List<Mensaje>>((ref) {
  final service = ref.watch(firebaseServiceProvider);

  return service.recibirMensajes();
});