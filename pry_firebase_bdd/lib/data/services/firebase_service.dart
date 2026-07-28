import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../domain/models/mensaje.dart';
import '../../domain/models/usuario.dart';

class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseDatabase _database;

  FirebaseService({
    FirebaseAuth? auth,
    FirebaseDatabase? database,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _database = database ?? FirebaseDatabase.instance;

  Stream<List<Usuario>> obtenerUsuarios() {
    return _database.ref('usuarios').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return [];

      final usuarios = <Usuario>[];
      final currentUid = _auth.currentUser?.uid;

      for (final value in data.values) {
        if (value is Map) {
          final usuario = Usuario.fromJson(value);
          if (usuario.uid != currentUid) {
            usuarios.add(usuario);
          }
        }
      }
      return usuarios;
    });
  }

  Stream<List<Mensaje>> recibirMensajes(String chatId) {
    return _database.ref('chats/$chatId').onValue.map((event) {
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
    required String chatId,
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

    await _database.ref('chats/$chatId').push().set(
      mensaje.toJson(),
    );
  }
}