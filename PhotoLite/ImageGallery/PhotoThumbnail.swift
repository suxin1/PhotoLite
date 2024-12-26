//
//  GridItemView.swift
//  PhotoView
//
//  Created by Suxin on 2024/3/22.
//

import SwiftUI
import AppKit
import QuickLookThumbnailing
//import QuickLook

enum ThumbnailSize {
    case small
    case middle
    case big
    var size: Int {
        switch self {
        case .small:
            return 100
        case .middle:
            return 200
        case .big:
            return 300
        }
    }
}



class Thumbnailing {
    static let previewGenerator = QLThumbnailGenerator()
    static let thumbnailSize = CGSize(width: 60, height: 90)
    
    static func generate(url: URL, size: Double, completion: @escaping (NSImage?) -> Void) {
        let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: size, height: size), scale: 1, representationTypes: .thumbnail)

        previewGenerator.generateBestRepresentation(for: request) { (thumbnail, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let tb = thumbnail {
                completion(tb.nsImage)
            }
        }
    }
}

struct PhotoThumbnail: View {
    @State private var image: NSImage?
    let size: Double
    let item: Photo
    
    func genThumbnail() {
        Thumbnailing.generate(url: item.url, size: size) { image in
            self.image = image
        }
    }

    var body: some View {
        ZStack(alignment: .center) {
            if let image = image {
                VStack {
                    VStack {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding([.top, .leading, .trailing], 24)
                    .frame(height: size - 32)
                    .padding([.bottom ], 8)
                    Text("\(item.name)")
                        .lineLimit(1)
                }
            } else {
                ProgressView()
            }
        }
        .frame(width: size, height: size)
        .onAppear(perform: {
            if (image == nil) {
                genThumbnail()
            }
        })
    }
}

//struct PhotoThumbnail_Previews: PreviewProvider {
//    static var img: URL? {
//        guard let documentDirectory = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else {
//            print("Failed to get picture directory")
//            return nil;
//        }
//        let documentDirectoryPath = documentDirectory.resolvingSymlinksInPath();
//        do {
//            let urls = try FileManager.default.contentsOfDirectory(at: documentDirectoryPath, includingPropertiesForKeys: nil).filter {
//                $0.isImage
//            }
//            if let first = urls.first {
//                return first
//            }
//        } catch {
//            return nil
//        }
//        return nil
//    }
//    
//    static var previews: some View {
//        if let image = img {
//            PhotoThumbnail(size: 300, item: Photo(url: image))
//        } else {
//            Text("Hello")
//        }
//        
//    }
//}
