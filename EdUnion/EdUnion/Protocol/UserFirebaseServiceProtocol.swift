//
//  UserFirebaseServiceProtocol.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/28.
//

protocol UserFirebaseServiceProtocol {
    func getStudentFollowList(studentID: String, completion: @escaping ([String]?, Error?) -> Void)
}
