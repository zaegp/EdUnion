# EdUnion
## 介紹
EdUnion 是一款老師能夠高效設置可選時段，並讓學生能夠在線媒合預約老師的應用程式

[![Download on the App Store](https://developer.apple.com/app-store/marketing/guidelines/images/badge-download-on-the-app-store.svg)](https://apps.apple.com/tw/app/edunion/id6692628566)
## 功能
- 媒合預約老師 - 直接預約有興趣的老師，省去溝通成本
- 可縮放的周/月行事曆 - 方便進行課程管理
- 聊天室 / 視訊課堂 - 讓溝通變得更容易
- 教材 - 在線分發教材
## 安裝
### Clone 此倉庫
```bash
https://github.com/zaegp/EdUnion.git
```
### 配置 GoogleService-Info.plist
1. 前往 [Firebase Console](https://console.firebase.google.com/)，並創建一個新的 Firebase 專案
2. 添加一個 iOS 應用，並根據 Firebase 指示輸入你的應用的 `iOS Bundle ID`。
3. 完成配置後，下載 Firebase 為你的應用生成的 `GoogleService-Info.plist` 文件。
4. 將 `GoogleService-Info.plist` 文件添加到你的 Xcode 專案的根目錄下。
## 使用方式
1. 選擇身份：學生 or 老師（後續可進行切換）
2. 使用 Apple ID 進行登入
3. 開始使用
## 回饋
有任何問題或回饋，請聯絡：szian516@gmail.com
