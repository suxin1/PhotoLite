//
//  DataModel.swift
//  PhotoView
//
//  Created by Suxin on 2024/3/22.
//

import Foundation
import AppKit

struct Constants {
    static var supportedExtensions: [String] = [
        "jpg",
        "jpeg",
        "png",
        "gif",
        "tiff",
        "tif",
        "bmp",
        "avif",
//        "jxl"
    ]
    
    static var rawExtensions: [String] = [
        "arw",
        "nef"
    ]
}


func requestDirectoryAccess(initialPath: String, completionHandler: @escaping (URL?) -> Void) {
    let openPanel = NSOpenPanel()
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = false
    openPanel.directoryURL = URL(fileURLWithPath: initialPath)

    openPanel.begin { (result) -> Void in
        if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
            if let directoryUrl = openPanel.url {
                completionHandler(directoryUrl)
            } else {
                completionHandler(nil)
            }
        } else {
            completionHandler(nil)
        }
    }
}


class DataModel: ObservableObject {
    @Published var items: [Photo] = []
//    static let supportedExtensions: [String] = ["jpg", "jpeg", "png", "gif", "tiff", "bmp", "raw"]
    
    init() {
        print("init DataModel")
        guard let documentDirectory = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first else {
            print("Failed to get picture directory")
            return;
        }
        let documentDirectoryPath = documentDirectory.resolvingSymlinksInPath();
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentDirectoryPath, includingPropertiesForKeys: nil).filter {
                $0.isImage
            }
            print(urls)
            for url in urls {
                
                let item = Photo(url: url, name: url.lastPathComponent )
                self.items.append(item)
            }
        } catch {
            print(error)
        }
//        print("attempt to get dirctory access")
//        requestDirectoryAccess(initialPath: documentDirectoryPath.absoluteString) { dir in
//            print("require dirctory access")
//            do {
//                let urls = try FileManager.default.contentsOfDirectory(at: dir!, includingPropertiesForKeys: nil).filter {
//                    $0.isImage
//                }
//                print(urls)
//                for url in urls {
//                    let item = Item(url: url)
//                    self.items.append(item)
//                }
//            } catch {
//                print(error)
//            }
//        }

    }
    
    func addItem(_ photo: Photo) {
        items.insert(photo, at: 0)
    }
    
    func removeItem(_ photo: Photo) {
        if let index = items.firstIndex(of: photo) {
            items.remove(at: index)
        }
    }
}

class AlbumDataModel: ObservableObject {
    public enum AlbumType {
        case directory
        case virtual
    }
    
    @Published var photos: [Photo] = []
    
//    static let supportedExtensions: [String] = ["jpg", "jpeg", "png", "gif", "tiff", "tif", "bmp", "raw"]
    
    private var current: Int?
    
    init() {}
    
    convenience init(with directory: URL) {
        self.init()
        
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).filter {
                $0.isImage
            }
            for url in urls {
                let photo = Photo(url: url, name: url.lastPathComponent)
                photos.append(photo)
            }
        } catch {
            print(error)
        }
    }
    
    convenience init(byFileUrl file: URL, cache: Bool = false) {
        self.init()
        let directoryUrl = file.deletingLastPathComponent()
        
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: directoryUrl, includingPropertiesForKeys: nil).filter {
                $0.isImage
            }
            
            if (cache) {
                PhotoCache.shared.initTask(list: urls, target: file)
            }
            
            for index in 0..<urls.count {
                let url = urls[index]
                if (url == file) {
                    current = index
                }
                let photo = Photo(url: urls[index], name: urls[index].lastPathComponent)
                photos.append(photo)
            }
        } catch {
            print(error)
        }
    }
    
    func count() -> Int {
        return photos.count;
    }
    
    func addPhoto(_ photo: Photo) {
        photos.insert(photo, at: 0)
    }
    
    func removePhoto(_ photo: Photo) {
        if let index = photos.firstIndex(of: photo) {
            photos.remove(at: index)
        }
    }
    
    func getPhotoIndex(byUrl url: URL) -> Int? {
        for index in 0..<photos.count {
            if (photos[index].url == url) {
                return index
            }
        }
        return nil
    }
    
    func getPhotoByIndex(_ index: Int?) -> Photo? {
        if let i = index {
            return photos[i]
        }
        return nil
    }
    
    // Generating thumbnail on demand
    // Could do generating in a weighted manner,
    // user currently is view or photo in view is weighted more then others
    func generatingThumbnail() {
        for photo in photos {
            
        }
    }
}
