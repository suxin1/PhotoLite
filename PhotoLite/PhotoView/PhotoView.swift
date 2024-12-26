//
//  ImageView.swift
//  PhotoView
//
//  Created by Suxin on 2024/3/23.
//

import SwiftUI
import AppKit
import CoreGraphics

enum PhotoInfoType {
    case Exif;
    case Histogram;
}


struct PhotoView: View {
    @Binding var photo: Photo?
    
    @State private var exif: NSDictionary? = nil
    
    @State private var image: CIImage? = nil
    
    @State private var infoDisplayState: [PhotoInfoType:Bool] = [.Exif: false, .Histogram: false]
    
//    var exif: Binding<NSDictionary?>
    func onToolbarButtonClick(type: PhotoInfoType) {
        infoDisplayState[type] = !infoDisplayState[type]!
    }
    
    func renderTypeOfUrl(url: URL) -> RenderType {
        let suffix = url.pathExtension
        if (suffix == "jxl") {
            return .swiftUI
        }
        return .metal
    }
    
    func extractExifInfo(image: CIImage) {
        self.image = image
        let info = image.properties["{Exif}"]
        let tiff = image.properties["{TIFF}"]
        let pixelHeight = image.properties["PixelHeight"]
        let pixelWidth = image.properties["PixelWidth"]
//        if let size = try! image.url?.resourceValues(forKeys:[.fileSizeKey]) {
//            print("size \(Float(size.fileSize ?? 0)/1000/1000)")
//        }
        guard let size = try! image.url?.resourceValues(forKeys:[.fileSizeKey]) else {
            return
        }
        var dataExtra:NSMutableDictionary = [:]
        dataExtra["PixelHeight"] = pixelHeight
        dataExtra["PixelWidth"] = pixelWidth
        dataExtra["FileSize"] = size.fileSize
        
        var data: NSDictionary = dataExtra as NSDictionary
        
        guard let _info = info else {
            return
        }
        data = data + (_info as! NSDictionary)
        guard let _tiff = tiff else {
            return
        }
        data = data + (_tiff as! NSDictionary)
        exif = data
//        print(image.properties)
    }
    
//    func histogramDisplay(inputImage: CIImage) -> CIImage {
//        let filter = CIFilter(name:"CIHistogramDisplayFilter")
//        filter.inputImage = areaHistogram(inputImage: inputImage)
//        filter.highLimit = 1
//        filter.height = 100
//        filter.lowLimit = 0
//        return filter.outputImage!
//    }
    
    var body: some View {
        if photo != nil {
            ZStack(alignment: .topTrailing) {
                
                AsyncLocalImage(url: photo!.url) { image in
                    let type = renderTypeOfUrl(url: photo!.url)
//                    extractExifInfo(image: image)
                    
                    switch type {
                    case .metal:
                        MetalImageView(image: image)
                    case .swiftUI:
                        Image(ciImage: image)
                            .resizable()
                            .scaledToFit()
                    }
//                    Image(ciImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 284)
                } placeholder: {
                    ProgressView()
                } onLoadFileSuccess: { image in
                    extractExifInfo(image: image)
                }
                
                VStack {
                    if (infoDisplayState[.Histogram]!) {
                        HistogramView(ciImage: image)
                            .transition(.move(edge: .trailing))
                    }
                    if (infoDisplayState[.Exif]!) {
                        ExifInfoView(data: $exif)
                    }
                }
                .offset(x: 0, y: 35)

            }
            .frame(alignment: .topLeading)
            .edgesIgnoringSafeArea(.all)
            .onContinuousHover(coordinateSpace: .local) { hover in
                PhotoViewEnvet.shared.handleHover(phase: hover)
            }
            .gesture (
                DragGesture().onChanged { gesture in
                    PhotoViewEnvet.shared.handleGesture(gesture: gesture)
                } 
//                    .onEnded { _ in
//                    PhotoViewEnvet.shared.onTrackpadRelease()
//                }
            )
            .toolbar {
                ToolbarItem {
                    Spacer()
                }
                ToolbarItem(id: "flexible-space-id") {
                    Button {
                        MetalViewModel.shared.reset()
                    } label: {
                        Image(systemName: "square.inset.filled")
    //                        .shadow(color: Color(.sRGBLinear, white: 0.3, opacity: 0.33), radius: 2, x: 3, y: 3)
                    }
                }
                ToolbarItem {
                    Button {
                        withAnimation {
                            onToolbarButtonClick(type: .Exif)
                        }
                    } label: {
                        Image(systemName: "info.square.fill")
                    }
                }
//                ToolbarItem {
//                    Button {
//                        withAnimation {
//                            onToolbarButtonClick(type: .Histogram)
//                        }
//                    } label: {
//                        Image(systemName: "h.square.fill")
//                    }
//                }
            }
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    @State static var photo: Photo? = Photo(url: URL(filePath: "/Users/suxin/Pictures/无标题.1png.png"), name: "xxx")
    static var previews: some View {
            PhotoView(photo: $photo)
    }
}
