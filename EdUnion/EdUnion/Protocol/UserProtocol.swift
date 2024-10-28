//
//  UserProtocol.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/28.
//

protocol UserProtocol {
    var id: String { get set }
    var fullName: String { get }
    var photoURL: String? { get }
}
