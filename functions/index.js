const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when a specific device's status changes.
 */
exports.sendDeviceAlert = functions.database
  .ref("devices/{deviceId}/status")
  .onUpdate(async (change, context) => {
    const status = change.after.val();
    const oldStatus = change.before.val();
    const deviceId = context.params.deviceId;

    if (status !== "TRIPPED" || oldStatus === "TRIPPED") return null;

    // 1. Find who this device is assigned to
    const assignedSnapshot = await admin.database().ref(`devices/${deviceId}/assigned_to`).once("value");
    const uid = assignedSnapshot.val();

    if (!uid) {
      console.log(`Device ${deviceId} is not assigned to any user.`);
      return null;
    }

    // 2. Get the user's FCM token
    const tokenSnapshot = await admin.database().ref(`database/users/${uid}/fcm_token`).once("value");
    const token = tokenSnapshot.val();

    if (!token) return null;

    const message = {
      notification: {
        title: "⚠️ ELCB ALERT!",
        body: `A power trip detected on device ${deviceId.substring(0,6)}...`,
      },
      token: token,
    };

    return admin.messaging().send(message);
  });

/**
 * Legacy support for user-path status changes.
 */
exports.sendTripAlert = functions.database
  .ref("database/users/{uid}/ELCB_SYSTEM/status")
  .onUpdate(async (change, context) => {
    const status = change.after.val();
    const uid = context.params.uid;

    if (status !== "TRIPPED") return null;

    const tokenSnapshot = await admin.database().ref(`database/users/${uid}/fcm_token`).once("value");
    const token = tokenSnapshot.val();
    if (!token) return null;

    const message = {
      notification: {
        title: "⚠️ ELCB Alert!",
        body: "A power trip has been detected on your ELCB monitor.",
      },
      token: token,
    };

    return admin.messaging().send(message);
  });
