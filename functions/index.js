const { https } = require('firebase-functions/v2');
const express = require('express');
const cors = require('cors');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

const app = express();

// 启用 CORS，允许所有来源访问
app.use(cors({ origin: true }));

// 解析传入的 JSON 请求
app.use(express.json());

app.post('/', (req, res) => {
  // 日志打印请求内容
  console.log('Request body received:', req.body);

  // 从环境变量中获取 appId 和 appCertificate
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;

  // 检查 appId 和 appCertificate 是否存在
  if (!appId || !appCertificate) {
    console.error('AGORA_APP_ID 或 AGORA_APP_CERTIFICATE 未在环境变量中设置。');
    return res.status(500).json({
      error: {
        message: "服务器配置错误。",
        status: "INTERNAL_ERROR"
      }
    });
  }

  const channelName = req.body.channelName;

  // 检查 channelName 是否正确
  if (!channelName) {
    console.log('缺少 channelName。');
    return res.status(400).json({
      error: {
        message: "必须提供 channelName。",
        status: "INVALID_ARGUMENT"
      }
    });
  }

  const uid = 0;
  const role = RtcRole.PUBLISHER;
  const expireTimeInSeconds = 2 * 3600; // 设置为2小时
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
    console.error('生成 token 时出错:', error);
    res.status(500).json({
      error: {
        message: "Internal Server Error",
        status: "INTERNAL_ERROR"
      }
    });
  }
});

// 导出函数，确保这一行在文件末尾，并且在 app 配置之后
exports.generateAgoraToken = https.onRequest(app);
