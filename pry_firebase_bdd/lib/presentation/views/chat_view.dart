import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String _usuario = 'UsuarioDemo';

  bool _enviando = false;

  String get _uidActual {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  bool get _puedeEnviar {
    return _controller.text.trim().isNotEmpty && !_enviando;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_actualizarBoton);
  }

  void _actualizarBoton() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();

    if (texto.isEmpty || _enviando) {
      return;
    }

    final usuarioActual = FirebaseAuth.instance.currentUser;

    if (usuarioActual == null) {
      _mostrarError('No existe un usuario autenticado.');
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final service = ref.read(firebaseServiceProvider);

      await service.enviarMensaje(
        texto: texto,
        autor: _usuario,
      );

      _controller.clear();

      await Future<void>.delayed(
        const Duration(milliseconds: 200),
      );

      _irAlFinal();
    } catch (error) {
      _mostrarError(
        'No se pudo enviar el mensaje: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  void _irAlFinal() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_actualizarBoton);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mensajesAsync = ref.watch(mensajesProvider);
    final uidActual = _uidActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat en Tiempo Real'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: mensajesAsync.when(
              data: (mensajes) {
                if (mensajes.isEmpty) {
                  return const Center(
                    child: Text('Todavía no hay mensajes'),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _irAlFinal();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final mensaje = mensajes[index];

                    final esMio =
                        uidActual.isNotEmpty &&
                        mensaje.autorId == uidActual;

                    return Align(
                      alignment: esMio
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(
                          maxWidth: 280,
                        ),
                        decoration: BoxDecoration(
                          color: esMio
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: esMio
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              mensaje.texto,
                              style: TextStyle(
                                color: esMio
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mensaje.autor,
                              style: TextStyle(
                                fontSize: 11,
                                color: esMio
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error al cargar mensajes:\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) {
                        if (_puedeEnviar) {
                          _enviarMensaje();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Enviar mensaje',
                    onPressed: _puedeEnviar
                        ? _enviarMensaje
                        : null,
                    icon: _enviando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}