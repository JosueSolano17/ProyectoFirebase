import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../domain/models/mensaje.dart';

class FirebaseService {
  final FirebaseAuth _auth;
  final DatabaseReference mensajesRef;

  FirebaseService({
    FirebaseAuth? auth,
    FirebaseDatabase? database,
  })  : _auth = auth ?? FirebaseAuth.instance,
        mensajesRef = (database ?? FirebaseDatabase.instance)
            .ref('chats/general');

  Stream<List<Mensaje>> recibirMensajes() {
    return mensajesRef.onValue.map((event) {
      final data = event.snapshot.value;

      if (data == null || data is! Map) {
        return <Mensaje>[];
      }

      final mensajes = <Mensaje>[];

      for (final value in data.values) {
        if (value is Map) {
          final json = Map<String, dynamic>.from(value);

          mensajes.add(
            Mensaje.fromJson(json),
          );
        }
      }

      mensajes.sort(
        (a, b) => a.timestamp.compareTo(b.timestamp),
      );

      return mensajes;
    });
  }

  Future<void> enviarMensaje({
    required String texto,
    required String autor,
  }) async {
    final textoLimpio = texto.trim();
    final autorLimpio = autor.trim();

    if (textoLimpio.isEmpty) {
      throw ArgumentError('El mensaje no puede estar vacío');
    }

    final usuarioActual = _auth.currentUser;

    if (usuarioActual == null) {
      throw StateError('El usuario no está autenticado');
    }

    final mensaje = Mensaje(
      texto: textoLimpio,
      autor: autorLimpio.isEmpty ? 'Anónimo' : autorLimpio,
      autorId: usuarioActual.uid,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await mensajesRef.push().set(
      mensaje.toJson(),
    );
  }
}