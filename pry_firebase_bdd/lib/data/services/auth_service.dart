import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../domain/models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Si el usuario solo existe en Auth pero no tiene perfil en la DB,
    // lo creamos automáticamente para que aparezca en la lista de contactos.
    final user = userCredential.user;
    if (user != null) {
      final snapshot = await _dbRef.child('usuarios/${user.uid}').get();
      if (!snapshot.exists) {
        final nuevoUsuario = Usuario(
          uid: user.uid,
          email: email.trim(),
          // Si tiene displayName en Auth lo usamos, si no, usamos la parte del correo.
          nombre: user.displayName ?? email.split('@').first,
        );
        await _dbRef.child('usuarios/${user.uid}').set(nuevoUsuario.toJson());
      }
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      final nuevoUsuario = Usuario(
        uid: user.uid,
        email: email.trim(),
        nombre: nombre.trim(),
      );

      await _dbRef.child('usuarios/${user.uid}').set(nuevoUsuario.toJson());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
