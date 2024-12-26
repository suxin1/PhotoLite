//
//  AlbumSwiper.swift
//  PhotoView
//
//  Created by Suxin on 2024/4/22.
//

import Foundation

struct Album: Hashable {
    let id = UUID()
    let url: URL
}

struct AlbumSwiper: Hashable, Identifiable{
    let id = UUID()
    let current: URL
}
