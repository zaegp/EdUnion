//
//  UserSession.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/27.
//

import FirebaseAuth
import SwiftUI

class UserSession {
    static let shared = UserSession()
    
    var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    var unwrappedUserID: String {
        guard let uid = currentUserID else {
            redirectToLogin()
            return ""
        }
        return uid
    }
    
    private init() {
       
    }
    
    func signOut(completion: @escaping (Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(nil)
            redirectToLogin()
        } catch let error as NSError {
            completion(error)
        }
    }
    
    func deleteAccount(userRole: String, completion: @escaping (Error?) -> Void) {
        UserFirebaseService.shared.updateUserStatusToDeleting(userID: unwrappedUserID, userRole: userRole) { error in
            if let error = error {
                completion(error)
            } else {
                self.signOut { _ in
                    self.redirectToLogin()
                }
            }
        }
    }
    
    private func redirectToLogin() {
        DispatchQueue.main.async {
            let authView = AuthenticationView()
            let hostingController = UIHostingController(rootView: authView)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = hostingController
                window.makeKeyAndVisible()
            }
        }
    }
}
