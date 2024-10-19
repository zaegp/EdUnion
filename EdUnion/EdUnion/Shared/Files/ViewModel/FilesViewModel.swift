//
//  FilesViewModel.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/18.
//

import Foundation
import SwiftUI

//class FilesViewModel: ObservableObject {
//    @Published var files: [FileItem] = []
//    @Published var studentInfos: [Student] = []
//    @Published var selectedFiles: [FileItem] = []
//    @Published var selectedStudentIDs: Set<String> = []
//    @Published var fileDownloadProgress: [URL: Float] = [:]
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//    
//    private let firebaseService = FileFirebaseService.shared
//    private let firestore = FileFirebaseService.firestore
//    private let userID = UserSession.shared.currentUserID ?? ""
//    private let userRole: UserRole
//    
//    init(userRole: UserRole) {
//        self.userRole = userRole
//    }
//    
//    func fetchFiles() {
//        isLoading = true
//        firebaseService.fetchUserFiles(userRole: userRole, userID: userID) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let files):
//                    self?.files = files
//                case .failure(let error):
//                    self?.errorMessage = error.localizedDescription
//                }
//            }
//        }
//    }
//    
//    func uploadFile(fileURL: URL, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
//        isLoading = true
//        firebaseService.uploadFile(fileURL: fileURL, fileName: fileName, ownerID: userID) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let downloadURL):
//                    self?.files.append(FileItem(localURL: fileURL, remoteURL: URL(string: downloadURL)!, downloadURL: downloadURL, fileName: fileName, storagePath: "files/\(fileName)"))
//                    completion(.success(downloadURL))
//                case .failure(let error):
//                    self?.errorMessage = error.localizedDescription
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//    
//    func cancelUpload() {
//        // 實現取消上傳的邏輯
//    }
//    
//    func sendFilesToStudents() {
//        // 實現發送文件給學生的邏輯
//    }
//    
//    func fetchStudentInfo(studentID: String, completion: @escaping (Student?) -> Void) {
//        // 實現獲取學生信息的邏輯
//    }
//    
//    // 其他業務邏輯方法...
//}
