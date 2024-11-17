//
//  AppDelegate.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift
import UserNotifications
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseConfiguration.shared.setLoggerLevel(.debug)
        FirebaseApp.configure()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if let error = error {
                        print("Notification authorization error: \(error)")
                    } else if granted {
                        DispatchQueue.main.async {
                            application.registerForRemoteNotifications()
                        }
                    }
                }

        Messaging.messaging().delegate = self
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
           Messaging.messaging().apnsToken = deviceToken
       }

       func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
           print("Failed to register for remote notifications: \(error)")
       }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM token: \(fcmToken)")

        sendTokenToServer(token: fcmToken)
    }

    private func sendTokenToServer(token: String) {
        guard let userRole = UserDefaults.standard.string(forKey: "userRole"),
              userRole == "teacher" else {
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
            } else {
                userRef.setData(["fcmToken": token], merge: true) { error in
                    if let error = error {
                        print("Error updating FCM token: \(error.localizedDescription)")
                    } else {
                        print("FCM token updated successfully for teacher \(userID).")
                    }
                }
            }
        }
    }
    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//            Messaging.messaging().apnsToken = deviceToken
//        }
//
//        func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//            print("Failed to register for remote notifications: \(error)")
//        }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}


