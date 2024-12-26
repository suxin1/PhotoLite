//
//  AsyncLocalImage.swift
//  PhotoView
//
//  Created by Suxin on 2024/3/23.
//
import SwiftUI
import Cocoa

func loadLocalImageAsync(url: URL, completion: @escaping (CIImage?) -> Void) {
    DispatchQueue.global().async {
        guard let ciImage = CIImage(contentsOf: url, options: [.expandToHDR: true]) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        DispatchQueue.main.async {
            completion(ciImage)
        }
    }
}

struct AsyncLocalImage<Content, Placeholder>: View where Content:View, Placeholder: View {
    var url: URL
    @State private var image: CIImage?
    @State private var fail: Bool = false
    
    private let content: (CIImage) -> Content
    private var placeholder: (() -> Placeholder)?
    
    private let onLoadFileSuccess: ((CIImage) -> Void)?
    init(
        url: URL,
        @ViewBuilder content: @escaping (CIImage) -> Content,
        @ViewBuilder placeholder  ph: @escaping () -> Placeholder,
        onLoadFileSuccess: ((CIImage) -> Void)?
    ) {
        self.url = url
        self.content = content
        self.placeholder = ph
        self.onLoadFileSuccess = onLoadFileSuccess
    }
    
    func loadImage() {
        PhotoCache.shared.load(url: url) { data in
            if let dt = data {
//                let ciImage = CIImage(cgImage: dt, options: [.expandToHDR: true])
                self.image = dt
                guard let onLoadSuccess = onLoadFileSuccess else {
                    return
                }
                onLoadSuccess(dt)
                self.fail = false
            } else {
                self.fail = true
            }
        }
    }
    
    var body: some View {
        ZStack {
//            Text("Image URL: \(url)")
            if (fail) {
                Text("图片加载失败")
            }
            else if let image = self.image {
                content(image)
            } else if let ph = placeholder {
                ph()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) {
            loadImage()
        }
    }
}
