// functions/index.js
const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onRequest} = require("firebase-functions/v2/https");


// Initialize with your project’s defaults (no need to pass databaseURL
// if you’ve already set up your Firebase project via the CLI)
admin.initializeApp();

exports.expireStaleGames = onSchedule(
  {
    schedule: "*/20 * * * *",   // every 5 minutes
    timeZone: "UTC",           // adjust if you need a different zone
    region: "us-central1",     // change to your preferred region
  },
  async () => {
    const nowSec    = Math.floor(Date.now() / 1000);
    const cutoffSec = nowSec - 5 * 60;  // 5 minutes ago

    const gamesRef = admin.database().ref("games");
    const snap     = await gamesRef
      .orderByChild("lastUpdated")
      .endAt(cutoffSec)
      .once("value");

    // Build a multi-location update where each stale game → null (deletes it)
    const updates = {};
    snap.forEach((child) => {
      updates[child.key] = null;
    });

    if (Object.keys(updates).length) {
      console.log("Deleting stale games:", Object.keys(updates));
      await gamesRef.update(updates);
    }
  },
);

exports.appleNotifications = onRequest(
  {
    region: "us-central1",   // same region as your scheduler, if you like
  },
  (req, res) => {
    console.log("🍏 Apple notification:", req.body);
    // TODO: verify the JWT in req.body, handle req.body.notificationType, etc.
    res.status(200).send("OK");
  },
);
