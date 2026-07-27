class Mensaje {
  final String texto;
  final String autor;
  final String autorId;
  final int timestamp;

  const Mensaje({
    required this.texto,
    required this.autor,
    required this.autorId,
    required this.timestamp,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      texto: json['texto']?.toString() ?? '',
      autor: json['autor']?.toString() ?? 'Anónimo',
      autorId: json['autorId']?.toString() ?? '',
      timestamp: _convertirTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'texto': texto,
      'autor': autor,
      'autorId': autorId,
      'timestamp': timestamp,
    };
  }

  static int _convertirTimestamp(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}