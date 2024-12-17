<div align="center">
  <img src="https://github.com/user-attachments/assets/5bfe0424-356e-4e95-ac78-226d8c2616ac" alt="title">
 <br><br>
  <a href="https://apps.apple.com/in/app/calcontrol/id6692630915"><img src="https://img.shields.io/badge/release-v1.3.1-blue" alt="App Release Version"></a>
  <a href="https://apps.apple.com/in/app/calcontrol/id6692630915"><img src="https://img.shields.io/badge/platform-iOS-green" alt="Platform iOS"></a>
  <a href="https://github.com/Eva0306/CalControl"><img src="https://img.shields.io/badge/language-Swift-orange" alt="Language Swift"></a>
  <br><br>
  <a> EdUnion 是一個讓老師和學生能夠在線媒合預約、並能夠在線上進行溝通及課程管理的 APP</a>
  <br><br>
</div>

### 重要訊息：測試 App 過程中，若是使用學生身份，歡迎選擇「子安」老師來進行互動測試，如：預約、聊天室功能
[Demo 影片](https://youtu.be/Zq5YWlvSxQY)

## 功能
- 老師能夠快速高效開設每天的可選時段，方便進行每日不同安排
- 學生能夠查看平台所有老師，尋找理想的老師進行溝通和預約
- 雙方在線溝通，課前課後隨時溝通課程資訊
- 線上文檔分享，教材分發更容易
- 可縮放的行事曆頁面方便查看每日課程

## 安裝
1. 下載應用程式(可直接開始使用，不需以下配置)

   <div style="display: flex; align-items: center; gap: 30px;">
   <a href="https://apps.apple.com/tw/app/edunion/id6692628566">
       <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Demo of the Nextcloud iOS files app" height="40">
   </a>
   </div>

2. clone 此專案
   ```bash
   git clone https://github.com/zaegp/EdUnion.git
   ```
3. 專案使用 Google Firebase 上傳資料

   - 本專案使用 Firebase Firestore 來存儲數據，因此需要配置 `GoogleService-Info.plist` 檔案。
   - 登入 [Firebase Console](https://console.firebase.google.com/)，選擇你的專案（如果還沒有專案，請創建一個新的專案）。
   - 進入「專案設定」並選擇「iOS 應用程式」，然後按照提示添加應用程式（如果還未添加）。
   - 下載生成的 `GoogleService-Info.plist` 檔案，並將其放置在你的 Xcode 專案目錄中。

## 使用方式

- 開啟應用程式後，使用 `Sign in with Apple` 進行登入，並填入基本資料。
- 行事曆頁面向上滑動能縮放成週視圖，左右滑動能夠切換月份，點擊具體日期能查看當日所有課程
  
### 老師
如何設置可選時段
1. 點擊 `個人檔案`
2. 進入 `可選時段`，設置顏色時間段的對應
3. 點擊右上角的行事曆，長按日期即可開始設置日期和時間段的對應

教材頁面點擊右上角的 `...` 能夠上傳檔案及進行教材的分發，長按檔案能夠編輯檔案名稱及刪除

### 學生
首頁有三個部分，左右滑切換頁面，皆可透過右上角搜尋按鈕針對姓名、履歷資料進行搜尋：
  1. 關注的老師：老師詳細頁面右上角點擊愛心即可關注
  2. 平台上所有老師
  3. 預約過的老師
- 點擊首頁老師即可進到詳細頁面，能直接預約老師所開設的可選時段，或先透過聊天室和老師詢問課程細節
  
## 螢幕截圖

<ul style="text-align: center; list-style-position: inside; margin-top: 5px; margin-bottom: 5px;">
    <li>學生首頁和老師首頁</li>
</ul>
<div style="display: flex; justify-content: flex-start; gap: 20px; margin-bottom: 10px;">
    <img src="https://github.com/user-attachments/assets/c8612a63-7b7a-4e50-8d4c-028ca4e6e74a" alt="Simulator Screenshot - 1" width="25%">
    <img src="https://github.com/user-attachments/assets/2ac83d76-35b1-4daa-a121-ac4933cdb70a" alt="Simulator Screenshot - 3" width="25%">
</div>
<br><br>
<ul style="text-align: center; font-weight: bold; margin-top: 5px; margin-bottom: 5px;">
    <li>老師詳細資訊及預約頁面
</ul>
<div style="display: flex; justify-content: center; gap: 10px; margin-bottom: 10px;">
    <img src="https://github.com/user-attachments/assets/86f3e470-d94c-44ea-97f9-5202d53b859a" alt="Simulator Screenshot - 2" width="25%">
    <img src="https://github.com/user-attachments/assets/84555129-a691-44c7-9a59-80aa30404d47" alt="Simulator Screenshot - 4" width="25%">
</div>
<br><br>
<ul style="text-align: center; font-weight: bold; margin-top: 5px; margin-bottom: 5px;">
    <li>行事曆
</ul>
<div style="display: flex; justify-content: center; gap: 10px; margin-bottom: 10px;">
    <img src="https://github.com/user-attachments/assets/969a8290-a460-4de1-952a-d5052f168760" alt="Simulator Screenshot - 2" width="25%">
    <img src="https://github.com/user-attachments/assets/d15da7c5-a9c6-4d42-9434-e8621833cc58" alt="Simulator Screenshot - 4" width="25%">
</div>
<br><br>
<ul style="text-align: center; font-weight: bold; margin-top: 5px; margin-bottom: 5px;">
    <li>聊天室
</ul>
<div style="display: flex; justify-content: center; gap: 10px; margin-bottom: 10px;">
    <img src="https://github.com/user-attachments/assets/97525472-9939-4619-8a18-7471e0962d62" alt="Simulator Screenshot - 2" width="25%">
    <img src="https://github.com/user-attachments/assets/b20f13db-3959-4da6-a361-1ca249665777" alt="Simulator Screenshot - 4" width="25%">
</div>
<br><br>
<ul style="text-align: center; font-weight: bold; margin-top: 5px; margin-bottom: 5px;">
    <li>老師收到新預約時會發送通知
</ul>
<div style="display: flex; justify-content: center; gap: 20px; margin-bottom: 10px;">
    <img src="https://github.com/user-attachments/assets/d29d42e2-820b-480c-b1a9-a29b6c053570" alt="Simulator Screenshot - 7" width="25%">
</div>

## 聯絡方式
有任何問題，請聯絡我們：[szian516@gmail.com](mailto:szian516@gmail.com)
