class Usuario {
  final String uid;
  final String email;
  final String nombre;

  const Usuario({
    required this.uid,
    required this.email,
    required this.nombre,
  });

  factory Usuario.fromJson(Map<dynamic, dynamic> json) {
    return Usuario(
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? 'Sin Nombre',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
    };
  }
}
