//
//  UserSession.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/27.
//

import FirebaseAuth

class UserSession {
    static let shared = UserSession()
    var currentUserID: String?
    
    private init() {
        if let userID = Auth.auth().currentUser?.uid {
            self.currentUserID = userID
        } else {
            print("Error: User is not logged in.")
        }
    }
}
