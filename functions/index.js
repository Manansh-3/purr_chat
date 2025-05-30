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
    const chatId = event.params.chatId;

    // Fetch receiver user document
    const userDoc = await admin.firestore().collection("users").doc(receiverId).get();
    const userData = userDoc.data();

    if (!userData) {
      logger.log("No user data found for", receiverId);
      return;
    }

    const fcmToken = userData.fcmToken;
    const userStatus = userData.status || "offline";

    // Skip if user is online
    if (userStatus.toLowerCase() === "online") {
      logger.log("User is online, skipping notification for", receiverId);
      return;
    }

    if (!fcmToken) {
      logger.log("No FCM token for user", receiverId);
      return;
    }

    // Count unread messages for this user in this chat
    const unreadSnapshot = await admin
      .firestore()
      .collection("chats")
      .doc(chatId)
      .collection("messages")
      .where("receiverId", "==", receiverId)
      .where("isRead", "==", false)
      .get();

    const unreadCount = unreadSnapshot.size;

    const payload = {
      notification: {
        title: `You got some notifications ☺️`,
        body: `You have ${unreadCount} unread message${unreadCount !== 1 ? 's' : ''}`,
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
