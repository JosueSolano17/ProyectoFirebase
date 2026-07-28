const { onValueCreated } = require("firebase-functions/v2/database");
const logger = require("firebase-functions/logger");

const { initializeApp } = require("firebase-admin/app");
const { getDatabase } = require("firebase-admin/database");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.notificarNuevoMensaje = onValueCreated(
  {
    ref: "/chats/{chatId}/{messageId}",
    instance: "chat2-13ee2-default-rtdb",
    region: "us-central1",
  },
  async (event) => {
    const mensaje = event.data.val();

    if (!mensaje) {
      logger.warn("El mensaje está vacío.");
      return null;
    }

    const texto = String(mensaje.texto || "").trim();
    const autor = String(mensaje.autor || "Usuario");
    const autorId = String(mensaje.autorId || "");

    if (!texto || !autorId) {
      logger.warn("El mensaje no contiene texto o autorId.", mensaje);
      return null;
    }

    const database = getDatabase();
    const tokensSnapshot = await database.ref("tokens").get();

    if (!tokensSnapshot.exists()) {
      logger.info("No existen tokens registrados.");
      return null;
    }

    const destinatarios = [];

    tokensSnapshot.forEach((usuarioSnapshot) => {
      const uid = usuarioSnapshot.key;

      // No notificar al dispositivo que envió el mensaje.
      if (uid === autorId) {
        return;
      }

      const valor = usuarioSnapshot.val();

      // Compatible con token guardado como objeto o texto.
      const token =
        typeof valor === "string" ? valor : valor?.token;

      if (token) {
        destinatarios.push({
          uid,
          token,
        });
      }
    });

    if (destinatarios.length === 0) {
      logger.info("No existen destinatarios para el mensaje.");
      return null;
    }

    const respuesta = await getMessaging().sendEachForMulticast({
      tokens: destinatarios.map((item) => item.token),

      notification: {
        title: autor,
        body: texto,
      },

      data: {
        type: "chat",
        chatId: event.params.chatId,
        messageId: event.params.messageId,
      },

      android: {
        priority: "high",
        notification: {
          channelId: "chat_messages",
          sound: "default",
        },
      },

      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

    logger.info(
      `Notificaciones correctas: ${respuesta.successCount}`,
    );

    logger.info(
      `Notificaciones fallidas: ${respuesta.failureCount}`,
    );

    // Eliminar tokens inválidos.
    const actualizaciones = {};

    respuesta.responses.forEach((resultado, index) => {
      if (resultado.success) {
        return;
      }

      const errorCode = resultado.error?.code;
      const destinatario = destinatarios[index];

      logger.error(
        `Error enviando a ${destinatario.uid}: ${errorCode}`,
      );

      if (
        errorCode === "messaging/registration-token-not-registered" ||
        errorCode === "messaging/invalid-registration-token"
      ) {
        actualizaciones[destinatario.uid] = null;
      }
    });

    if (Object.keys(actualizaciones).length > 0) {
      await database.ref("tokens").update(actualizaciones);
    }

    return null;
  },
);