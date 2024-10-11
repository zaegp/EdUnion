//
//  File.swift
//  EdUnion
//
//  Created by Rowan Su on 2024/10/11.
//

import FirebaseCore

struct FileItem {
    let localURL: URL?
    let remoteURL: URL
    let downloadURL: String
    let fileName: String
}
