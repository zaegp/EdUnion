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
    @State private var currentNonce: String?
    @State private var showSwitchRoleView = false
    let userRole = UserDefaults.standard.string(forKey: "userRole")
    
    var body: some View {
        ZStack {
            Color.myBackground
                    .edgesIgnoringSafeArea(.all)
//            RadialGradientView()
//                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer().frame(height: 50)
                
                VStack {
                    Text("Sign in with")
                        .font(.system(size: 20))
                        .padding(.bottom, 5)
                    
                    Text("EdUnion")
                        .font(.system(size: 36))
                        .bold()
                        .padding(.bottom, 50)
                }
                
                Spacer()
                
                VStack {
                    Text("當前身份是: \(userRole)")
                        .font(.system(size: 16))
                        .foregroundColor(.myBlack)
                        .padding(.bottom, 20)
                    
                    Button(action: {
                        showSwitchRoleView = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.backward")
                                .foregroundColor(.myBlack)
                            
                            Text("切換身份")
                                .foregroundColor(.myBlack)
                                .font(.system(size: 16))
                        }
                    }
//                    .padding(.top, 20)
                }
                
                Spacer()
                
                SignInWithAppleButton(
                    onRequest: { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        handleSignInWithApple(result: result)
                    }
                )
                .background(.clear)
                .signInWithAppleButtonStyle(.black)
                .frame(width: 280, height: 45)
                .compositingGroup()
                .shadow(radius: 5)
                
                Spacer().frame(height: 50)
            }
            
            
        }
        .sheet(isPresented: $showSwitchRoleView) {
            SwitchRoleViewControllerRepresentable()
        }
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
    
    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
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
                    
                    let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
                    
                    Auth.auth().signIn(with: credential) { (authResult, error) in
                        if let error = error {
                            print("Error signing in with Apple: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let uid = authResult?.user.uid else { return }
                        
                        let db = Firestore.firestore()
                        let collectionName = (userRole == "teacher") ? "teachers" : "students"
                        let userRef = db.collection(collectionName).document(uid)
                        
                        userRef.getDocument { (document, error) in
                            if let error = error {
                                print("Error checking user data: \(error.localizedDescription)")
                                return
                            }
                            
                            if document?.exists == true {
                                navigateToMainApp()
                            } else {
//                                appleIDCredentialForProfileSetup = appleIDCredential
                                saveUserData(userRef: userRef, appleIDCredential: appleIDCredential)
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
    
    private func saveUserData(userRef: DocumentReference, appleIDCredential: ASAuthorizationAppleIDCredential) {
            var userData: [String: Any] = [
                "fullName": (appleIDCredential.fullName?.givenName ?? "") + " " + (appleIDCredential.fullName?.familyName ?? ""),
                "email": appleIDCredential.email ?? "",
                "userID": appleIDCredential.user,
                "photoURL": "",
                "status": "normal",
                "blockList": []
            ]
            
            if userRole == "student" {
                userData["followList"] = [String]()
                userData["usedList"] = [String]()
            } else {
                userData["totalCourses"] = Int()
                userData["timeSlots"] = [String]()
                        userData["selectedTimeSlots"] = [String: String]()
            }
            
            userRef.setData(userData) { error in
                if let error = error {
                    print("Error saving user data to Firestore: \(error.localizedDescription)")
                } else {
                    print("User data successfully saved to Firestore")
                    
                    navigateToIntroVC()
//                    if userRole == "teacher" {
//                        navigateToIntroVC()
//                    } else {
//                        navigateToMainApp()
//                    }
                }
            }
        }
    
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

struct RadialGradientView: View {
    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: [Color(hex: "#eeeeee"), Color(hex: "#ff6347"), Color(hex: "#252525")]),
            center: .bottomLeading,
            startRadius: 20,
            endRadius: 300
        )
        .edgesIgnoringSafeArea(.all)
    }
}

struct SwitchRoleViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let chooseRoleVC = ChooseRoleVC()
        return chooseRoleVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

#Preview {
    AuthenticationView()
}
