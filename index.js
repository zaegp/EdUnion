const functions = require('firebase-functions');
const cors = require('cors');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

// 啟用 CORS
const corsHandler = cors({ origin: true });

exports.generateAgoraToken = functions.https.onRequest((req, res) => {
  corsHandler(req, res, () => {
    const appId = 'dffc6ad07ded418683e4b403b9ee8be1';
    const appCertificate = '2db3bc5602e6415384f39cbc54c2e27b';

    console.log('收到的請求:', req.body);

    const channelName = req.body.channelName;
    if (!channelName) {
      return res.status(400).json({
        error: {
          message: "必須提供 channelName。",
          status: "INVALID_ARGUMENT"
        }
      });
    }

    const uid = 0;
    const role = RtcRole.PUBLISHER;
    const expireTimeInSeconds = req.body.expireTimeInSeconds || 3600;
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
      res.json({ token });
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
});