//
//  File.swift
//  PhotoView
//
//  Created by Suxin on 2024/4/23.
//

import Foundation
import AppKit

func loadLocalImageAsync3(url: URL, completion: @escaping (CIImage?) -> Void) {
    DispatchQueue.global().async {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        let imageOptions = [ kCGImageSourceShouldCacheImmediately: true ] as CFDictionary
        
        let cgImage = CGImageSourceCreateImageAtIndex(source, 0, imageOptions)

        DispatchQueue.main.async {
            completion(CIImage(cgImage: cgImage!, options: [.cacheImmediately: true]))
        }
    }
}

func loadLocalImageAsync2(url: URL, completion: @escaping (CIImage?) -> Void) {
    DispatchQueue.global().async {
        let decodingOptions: [CIImageOption: Any] = [.cacheImmediately: true]
        if (url.isPhotoRaw) {
            let rawFilter = CIRAWFilter(imageURL: url)
//            let rawimg = rawFilter?.outputImages
            guard let ciImage = rawFilter?.outputImage else {
                DispatchQueue.main.async {
                    completion(nil);
                }
                return
            }
            DispatchQueue.main.async {
                completion(ciImage)
            }
        } else {
            guard let ciImage = CIImage(contentsOf: url, options: decodingOptions) else {
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
}

class FileOperation {
    var url: URL
    private var completion: ((CIImage?) -> Void)? = nil
    private var innerCompletion: (URL, CIImage?) -> Void
    
    init(url: URL, onComplete: @escaping (URL, CIImage?) -> Void) {
        self.url = url
        self.innerCompletion = onComplete
        excute()
    }
    
    func excute() {
        loadLocalImageAsync2(url: url) {data in
            if (self.completion != nil) {
                self.completion!(data)
            }
            self.innerCompletion(self.url, data)
        }
    }
    
    func register(completion: @escaping (CIImage?) -> Void) {
        self.completion = completion
    }
}

class PhotoCache {
    private var photoUrls: [URL] = []
    
    private var weightedList: [URL] = []
    
    private var cache: [URL:CIImage] = [:]
    
    private var operations: [URL:FileOperation] = [:]
    
    private let max = 5
    
    static let shared:PhotoCache = PhotoCache()
    
    func initTask(list urls: [URL], target: URL) {
        photoUrls = urls
        weightedList = []
        cache = [:]
        generateWeightedList(target: target)
        initOperation()
    }
    
    func clear() {
        photoUrls = []
        weightedList = []
        cache = [:]
    }
    
    func generateWeightedList(target: URL) {
        var newList: [URL] = []
        guard let targetIndex = photoUrls.firstIndex(of: target) else {
            return
        }
        
        var list: [Int] = []
        newList.append(photoUrls[targetIndex])
        list.append(targetIndex)
        
        var left = targetIndex - 1
        var right = targetIndex + 1
        
        var switcher = 0
        
        for _ in 0..<(max - 1) {
            if (switcher == 0) {
                if (left > 0) {
                    newList.append(photoUrls[left])
                    list.append(left)
                    left -= 1
                    switcher = 1
                    continue
                } else if (right < photoUrls.count) {
                    newList.append(photoUrls[right])
                    list.append(right)
                    right += 1
                    switcher = 1
                    continue
                }
            }
            
            if (switcher == 1) {
                if (right < photoUrls.count) {
                    newList.append(photoUrls[right])
                    list.append(right)
                    right += 1
                    switcher = 0
                    continue
                } else if (left > 0) {
                    newList.append(photoUrls[left])
                    list.append(left)
                    left -= 1
                    switcher = 0
                    continue
                }
            }
        }
        print("result -----> \(list)")
        
        weightedList = newList
    }
    
    // remove FileOperation from operation list when operation complete
    func cacheComplete(url:URL, data: CIImage?) {
        if (weightedList.contains(where: { $0 == url})) {
            print("add cache")
            cache[url] = data
        }
        operations.removeValue(forKey: url)
    }
    
    func initOperation() {
        if (weightedList.count > 0) {
            for url in weightedList {
                addOperation(url: url)
            }
        }
    }
    
    func addOperation(url:URL) -> FileOperation {
        operations[url] = FileOperation(url: url, onComplete: cacheComplete)
        return operations[url]!
    }
    
    func sync() {
        // clean up memory cache
        for url in cache.keys {
            if (!weightedList.contains(where: { $0 == url})) {
                cache.removeValue(forKey: url)
            }
        }
        for url in weightedList {
            if (!(cache.contains(where: { $0.key == url }) || operations.contains(where: { $0.key == url})) ) {
                addOperation(url: url)
            }
        }
    }
    
    func load(url: URL, completion: @escaping (CIImage?) -> Void) {
        if (cache.contains(where: { $0.key == url})) {
            print("---------> load from cache")
            completion(cache[url])
        } else if (operations.contains(where: { $0.key == url})) {
            print("---------> load from operation")
            operations[url]?.register(completion: completion)
        } else {
            print("---------> load with new operation")
            addOperation(url: url).register(completion: completion)
        }
    }
}
