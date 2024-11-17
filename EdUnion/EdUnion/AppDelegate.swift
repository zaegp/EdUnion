//
//  AppDelegate.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import Firebase
import UserNotifications
import IQKeyboardManagerSwift
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - App Lifecycle
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configureFirebase()
        configureNotifications(for: application)
        configureKeyboard()
        return true
    }
    
    // MARK: - Firebase Setup
    private func configureFirebase() {
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }
    
    // MARK: - Notifications Setup
    private func configureNotifications(for application: UIApplication) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            } else if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Messaging Delegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM token: \(fcmToken)")
        uploadFCMTokenToServer(fcmToken)
    }
    
    private func uploadFCMTokenToServer(_ token: String) {
        guard let userRole = UserDefaults.standard.string(forKey: "userRole"), userRole == "teacher" else {
            print("User is not a teacher, skipping FCM Token update.")
            return
        }
        
        let userID = UserSession.shared.unwrappedUserID
        let userRef = Firestore.firestore().collection(Constants.teachersCollection).document(userID)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            let existingToken = document?.data()?["fcmToken"] as? String
            if existingToken == token {
                print("FCM Token is already up to date.")
                return
            }
            
            userRef.setData(["fcmToken": token], merge: true) { error in
                if let error = error {
                    print("Error updating FCM token: \(error.localizedDescription)")
                } else {
                    print("FCM token updated successfully for teacher \(userID).")
                }
            }
        }
    }
    
    // MARK: - Keyboard Setup
    private func configureKeyboard() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
    }
    
    // MARK: - UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Resources specific to discarded scenes can be released here.
    }
}
