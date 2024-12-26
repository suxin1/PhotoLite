//
//  extension.swift
//  PhotoView
//
//  Created by Suxin on 2024/4/3.
//

//import AppKit
import Foundation
import CoreGraphics
import CoreImage
import SwiftUI
import MetalKit

extension NSImage {
    /// Generates a CIImage for this NSImage.
    /// - Returns: A CIImage optional.
    func ciImage() -> CIImage? {
        if let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return CIImage(cgImage: cgImage)
        }
        return nil
    }
    
    /// Generates an NSImage from a CIImage.
    /// - Parameter ciImage: The CIImage
    /// - Returns: An NSImage optional.
    static func fromCIImage(_ ciImage: CIImage) -> NSImage {
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}




public extension Image {
    private static let context = CIContext(options: nil)

    init(ciImage: CIImage) {

#if canImport(UIKit)
        // Note that making a UIImage and then using that to initialize the Image doesn't seem to work, but CGImage is fine.
        if let cgImage = Self.context.createCGImage(ciImage, from: ciImage.extent) {
            self.init(cgImage, scale: 1.0, orientation: .up, label: Text(""))
        } else {
            self.init(systemName: "questionmark")
        }
#elseif canImport(AppKit)
        // Looks like the NSCIImageRep is slightly better optimized for repeated runs,
        // guessing it doesn't actually render the bitmap unless it needs to.
        let rep = NSCIImageRep(ciImage: ciImage)
        guard rep.size.width <= 10000, rep.size.height <= 10000 else {        // simple test to make sure we don't have overflow extent
            self.init(nsImage: NSImage())
            return
        }
        let nsImage = NSImage(size: rep.size)    // size affects aspect ratio but not resolution
        nsImage.addRepresentation(rep)
        self.init(nsImage: nsImage)
#endif
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}


extension URL {
    var isImage: Bool {
        let fileExtension = self.pathExtension.lowercased()
        return Constants.supportedExtensions.contains(fileExtension) || Constants.rawExtensions.contains(fileExtension)
    }
    
    var isPhotoRaw: Bool {
        let fileExtension = self.pathExtension.lowercased()
        return Constants.rawExtensions.contains(fileExtension)
    }
    
    var isDirectory: Bool? {
        do {
            return (try resourceValues(forKeys: [URLResourceKey.isDirectoryKey]).isDirectory)
        }
        catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
}
