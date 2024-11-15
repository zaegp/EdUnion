//
//  File.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/11.
//

import FirebaseCore

struct FileItem {
    var localURL: URL?
    let remoteURL: URL
    let downloadURL: String
    var fileName: String
    var storagePath: String?
}
