const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const express = require('express');
const cors = require('cors');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.post('/', (req, res) => {
  console.log('Request body received:', req.body);

  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;

  if (!appId || !appCertificate) {
    console.error('AGORA_APP_ID 或 AGORA_APP_CERTIFICATE 未在環境變數中設置。');
    return res.status(500).json({
      error: {
        message: "server 配置錯誤。",
        status: "INTERNAL_ERROR"
      }
    });
  }

  const channelName = req.body.channelName;

  if (!channelName) {
    console.log('缺少 channelName。');
    return res.status(400).json({
      error: {
        message: "必須提供 channelName。",
        status: "INVALID_ARGUMENT"
      }
    });
  }

  const uid = 0;
  const role = RtcRole.PUBLISHER;
  const expireTimeInSeconds = 2 * 3600; 
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpireTime = currentTimestamp + expireTimeInSeconds;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      role,
      privilegeExpireTime
    );

    console.log('生成的 token:', token);
    res.json({ token, appId });
  } catch (error) {
    console.error('生成 token 時出錯:', error);
    res.status(500).json({
      error: {
        message: "Internal Server Error",
        status: "INTERNAL_ERROR"
      }
    });
  }
});

exports.generateAgoraToken = onRequest(app);

exports.notifyTeacherOnNewAppointment = onDocumentCreated("appointments/{appointmentID}", async (event) => {
  const snapshot = event.data;
  const appointmentData = snapshot.data();

  if (!appointmentData) {
    console.log("No data in the created document.");
    return null;
  }

  const teacherID = appointmentData.teacherID;

  if (!teacherID) {
    console.log("No teacherID found in appointment, skipping notification.");
    return null;
  }

  try {
    const teacherDoc = await admin.firestore().collection("teachers").doc(teacherID).get();
    const teacherData = teacherDoc.data();

    if (!teacherData) {
      console.log(`No data found for teacher ${teacherID}`);
      return null;
    }

    const fcmToken = teacherData.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token found for teacher ${teacherID}`);
      return null;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: "EdUnion",
        body: `您有一个新的課程預約`,
      },
      data: {
        appointmentID: event.params.appointmentID,
        status: appointmentData.status,
      },
    };

    await admin.messaging().send(message);
    console.log(`Notification sent to teacher ${teacherID}`);
  } catch (error) {
    console.error("Error sending notification:", error);
  }

  return null;
});