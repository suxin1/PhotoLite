//
//  Item.swift
//  PhotoView
//
//  Created by Suxin on 2024/3/22.
//

import SwiftUI
import CryptoKit

func MD5(string: String) -> String {
    let digest = Insecure.MD5.hash(data: Data(string.utf8))
    return digest.map {
        String(format: "%02hhx", $0)
    }
    .joined()
}

struct Photo: Hashable {
//    let id = UUID()
    let url: URL
    let name: String
    var isRaw: Bool {
        return self.url.isPhotoRaw
    }
    var md5: String {
        return MD5(string: self.url.absoluteString)
    }
}

class ThumbnailCache: ObservableObject {
//    @Published 
}


//extension Photo: Equatable {
//    static func ==(lhs: Photo, rhs: Photo) -> Bool {
//        return lhs.id == rhs.id && lhs.url == rhs.url
//    }
//}
