//
//  IntroViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/15.
//

import UIKit

// class IntroViewModel {
//    var userID = UserSession.shared.unwrappedUserID
//    var userRole = UserDefaults.standard.string(forKey: "userRole") ?? "teacher"
//    var name: String = ""
//    var resumeData: [String] = []
//    var profileImageURL: String?
//    
//    var onUserDataSaved: (() -> Void)?
//    var onErrorOccurred: ((Error) -> Void)?
//
//    func saveUserData(name: String, resumeData: [String], profileImage: UIImage?) {
//
//        if let profileImage = profileImage {
//            UserFirebaseService.shared.uploadProfileImage(profileImage, forUserID: userID, userRole: userRole) { [weak self] result in
//                switch result {
//                case .success(let urlString):
//                    self?.profileImageURL = urlString
//                    self?.saveData(name: name, resumeData: resumeData, profileImageURL: urlString)
//                case .failure(let error):
//                    self?.onErrorOccurred?(error)
//                }
//            }
//        } else {
//            saveData(name: name, resumeData: resumeData, profileImageURL: nil)
//        }
//    }
//
//    private func saveData(name: String, resumeData: [String], profileImageURL: String?) {
//        var data: [String: Any] = ["fullName": name]
//        if !resumeData.isEmpty {
//            data["resume"] = resumeData
//        }
//        if let profileImageURL = profileImageURL {
//            data["photoURL"] = profileImageURL
//        }
//        
//        UserFirebaseService.shared.saveUserData(userID: userID!, userRole: userRole, data: data) { [weak self] error in
//            if let error = error {
//                self?.onErrorOccurred?(error)
//            } else {
//                self?.onUserDataSaved?()
//            }
//        }
//    }
// }
