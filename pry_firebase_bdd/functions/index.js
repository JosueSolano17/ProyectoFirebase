const {onValueCreated} = require("firebase-functions/database");
const {initializeApp} = require("firebase-admin/app");
const {getDatabase} = require("firebase-admin/database");
const {getMessaging} = require("firebase-admin/messaging");
const {logger} = require("firebase-functions");

initializeApp();

exports.notificarNuevoMensaje = onValueCreated(
    "/chats/general/{messageId}",
    async (event) => {
      const mensaje = event.data.val();

      if (!mensaje) {
        logger.warn("El mensaje está vacío");
        return null;
      }

      const texto = mensaje.texto || "Tienes un mensaje nuevo";
      const autor = mensaje.autor || "Chat";
      const autorId = mensaje.autorId || "";

      const tokensSnapshot = await getDatabase()
          .ref("tokens")
          .get();

      if (!tokensSnapshot.exists()) {
        logger.info("No existen dispositivos registrados");
        return null;
      }

      const dispositivos = tokensSnapshot.val();

      const tokensDestinatarios = Object.entries(dispositivos)
          .filter(([uid]) => uid !== autorId)
          .map(([, datos]) => datos.token)
          .filter((token) =>
            typeof token === "string" && token.length > 0,
          );

      if (tokensDestinatarios.length === 0) {
        logger.info("No existen destinatarios");
        return null;
      }

      const respuesta = await getMessaging()
          .sendEachForMulticast({
            tokens: tokensDestinatarios,

            notification: {
              title: autor,
              body: texto,
            },

            data: {
              chatId: "general",
              messageId: event.params.messageId,
            },

            android: {
              priority: "high",
              notification: {
                channelId: "chat_messages",
                sound: "default",
              },
            },
          });

      logger.info(
          `Notificaciones correctas: ${respuesta.successCount}`,
      );

      logger.info(
          `Notificaciones fallidas: ${respuesta.failureCount}`,
      );

      return null;
    },
);