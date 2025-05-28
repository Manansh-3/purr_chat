const admin = require("firebase-admin");
admin.initializeApp();

const { onDocumentCreated } = require("firebase-functions/firestore");
const { logger } = require("firebase-functions");

exports.sendNewMessageNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    const message = snap.data();

    logger.log("New message:", message);

    const receiverId = message.receiverId;
    const senderName = message.senderId || "Someone";

    const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      logger.log("No FCM token for user", receiverId);
      return;
    }

    const payload = {
      notification: {
        title: `${senderName}`,
        body: message.text || "Sent you a message!",
      },
      token: fcmToken,
    };

    try {
      await admin.messaging().send(payload);
      logger.log("Notification sent to", receiverId);
    } catch (error) {
      logger.error("Error sending notification:", error);
    }
  }
);
