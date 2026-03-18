const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when ELCB status changes.
 * Sends an FCM push notification if the status becomes "TRIPPED".
 */
exports.sendTripAlert = functions.database
  .ref("database/users/{uid}/ELCB_SYSTEM/status")
  .onUpdate(async (change, context) => {
    const status = change.after.val();
    const oldStatus = change.before.val();
    const uid = context.params.uid;

    console.log(`Status changed for user ${uid}: ${oldStatus} -> ${status}`);

    // Proceed only if status changed TO "TRIPPED"
    if (status !== "TRIPPED" || oldStatus === "TRIPPED") {
      return null;
    }

    // Retrieve the user's FCM token from the database
    const tokenSnapshot = await admin.database()
      .ref(`database/users/${uid}/fcm_token`)
      .once("value");

    const token = tokenSnapshot.val();

    if (!token) {
      console.log(`No FCM token found for user ${uid}. Cannot send alert.`);
      return null;
    }

    // Construct the push notification message
    const message = {
      notification: {
        title: "⚠️ ELCB Alert!",
        body: "A power trip has been detected on your ELCB monitor. Check immediately.",
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        status: "TRIPPED",
        user_id: uid,
      },
      token: token,
    };

    try {
      // Send the notification using Firebase Cloud Messaging
      const response = await admin.messaging().send(message);
      console.log("Successfully sent alert notification:", response);
      return response;
    } catch (error) {
      console.error("Error sending alert notification:", error);
      return null;
    }
  });
