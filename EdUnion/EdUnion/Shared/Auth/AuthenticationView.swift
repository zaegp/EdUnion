//
//  AuthenticationView.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/9/26.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

struct AuthenticationView: View {
    @State private var currentNonce: String? // 保存生成的 nonce
    
    var body: some View {
        SignInWithAppleButton(
            onRequest: { request in
                let nonce = randomNonceString() // 生成 nonce
                currentNonce = nonce // 保存 nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce) // 將 nonce 哈希化後傳遞
            },
            onCompletion: { result in
                
                switch result {
                case .success(let authResults):
                    
                    switch authResults.credential {
                    case let appleIDCredential as ASAuthorizationAppleIDCredential:
                        guard let nonce = currentNonce else {
                            print("Invalid state: A login callback was received, but no login request was sent.")
                            return
                        }
                        
                        guard let appleIDToken = appleIDCredential.identityToken else {
                            print("Unable to fetch identity token")
                            return
                        }
                        
                        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                            return
                        }
                        
                        // Firebase Authentication with Apple
                        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                                  idToken: idTokenString,
                                                                  rawNonce: nonce)
                        
                        Auth.auth().signIn(with: credential) { (authResult, error) in
                            if let error = error {
                                print("Error signing in with Apple: \(error.localizedDescription)")
                                return
                            }
                            
                            // Successfully signed in
                            guard let uid = authResult?.user.uid else { return }
                            
                            // Save user data to Firestore
                            let userRole = UserDefaults.standard.string(forKey: "userRole")
                            let db = Firestore.firestore()
                            // Determine collection name based on user role
                            let collectionName = (userRole == "teacher") ? "teachers" : "students"
                            let userRef = db.collection(collectionName).document(uid)
                            
                            // Check if the user already exists in the collection
                            userRef.getDocument { (document, error) in
                                if let error = error {
                                    print("Error checking user data: \(error.localizedDescription)")
                                    return
                                }
                                
                                if document?.exists == true {
                                    // User exists, navigate to main app
                                    navigateToMainApp()
                                } else {
                                    // User does not exist, this is the first login
                                    userRef.setData([
                                        "fullName": (appleIDCredential.fullName?.givenName ?? "") + " " + (appleIDCredential.fullName?.familyName ?? ""),
                                        "email": appleIDCredential.email ?? "",
                                        "userID": appleIDCredential.user
                                    ]) { error in
                                        if let error = error {
                                            print("Error saving user data to Firestore: \(error.localizedDescription)")
                                        } else {
                                            print("User data successfully saved to Firestore")
                                            
                                            if userRole == "teacher" {
                                                navigateToIntroVC()
                                            } else {
                                                // Otherwise, navigate to main app
                                                navigateToMainApp()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    case let passwordCredential as ASPasswordCredential:
                        let username = passwordCredential.user
                        let password = passwordCredential.password
                        print(username, password)
                        
                    default:
                        break
                    }
                case .failure(let error):
                    print("failure", error)
                }
            }
        )
        .background(Color.white)
        .signInWithAppleButtonStyle(.whiteOutline)
        .frame(width: 280, height: 45)
    }
    
    private func navigateToMainApp() {
        if let userRole = UserDefaults.standard.string(forKey: "userRole") {
            let mainVC = TabBarController(userRole: userRole)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = mainVC
                window.makeKeyAndVisible()
            }
        } else {
            print("Error: User role not found in UserDefaults.")
            // 在此處處理沒有角色的情況
        }
    }
    
    private func navigateToIntroVC() {
        let introVC = IntroVC()
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = introVC
            window.makeKeyAndVisible()
        }
    }
    
    // Helper functions for nonce
    private func randomNonceString(length: Int = 32) -> String {
        let charset: Array<Character> =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    AuthenticationView()
}
