//
//  SceneDelegate.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/11.
//

import UIKit
import SwiftUI
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        configureRootViewController()
        window?.makeKeyAndVisible()
    }
    
    private func configureRootViewController() {
        if let userRole = UserDefaults.standard.string(forKey: "userRole") {
            print("已選擇角色：\(userRole)")
            
            if let currentUser = Auth.auth().currentUser {
                setTabBarController(for: userRole, user: currentUser)
            } else {
                print("已選擇角色但未登入，顯示登入畫面。")
                setAuthenticationView()
            }
        } else {
            print("未選擇角色，顯示角色選擇畫面。")
            setChooseRoleView()
        }
    }
    
    private func setTabBarController(for role: String, user: User) {
        let tabBarController = TabBarController(userRole: role)
        window?.rootViewController = tabBarController
    }
    
    private func setAuthenticationView() {
        let authView = AuthenticationView()
        let hostingController = UIHostingController(rootView: authView)
        window?.rootViewController = hostingController
    }
    
    private func setChooseRoleView() {
        window?.rootViewController = ChooseRoleVC()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later,
        // as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
}
