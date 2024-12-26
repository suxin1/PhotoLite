//
//  HistogramView.swift
//  PhotoView
//
//  Created by Suxin on 2024/5/17.
//

import SwiftUI
import CoreImageExtensions
import Charts
import Accelerate

func areaHistogramFilter(_ input: CIImage, rect: CGRect, count: Int = 100, scale: Float = 100.0) -> CIImage?
{
    let filter = CIFilter(name:"CIAreaHistogram")
    filter?.setValue(input, forKey: kCIInputImageKey)
    filter?.setValue(CIVector(cgRect: rect), forKey: "inputExtent")
    filter?.setValue(count, forKey: "inputCount")
    filter?.setValue(scale, forKey: "inputScale")
    return filter?.outputImage
}

//func areaLogarithmicHistogram(inputImage: CIImage) -> CIImage {
//    let filter = CIFilter.areaLogarithmicHistogram()
//    filter.inputImage = inputImage
//    filter.count = 256
//    filter.scale = 15
//    filter.extent = CGRect(
//        x: inputImage.extent.width/2-250,
//        y: inputImage.extent.height/2-250,
//        width: 500,
//        height: 500)
//    return filter.outputImage!
//} 


func areaLogHistogramFilter(_ input: CIImage, rect: CGRect, count: Int = 256, scale: Float = 1.0) -> CIImage? {
    let filter = CIFilter(name:"CIAreaLogarithmicHistogram")
    filter?.setValue(input, forKey: kCIInputImageKey)
    filter?.setValue(CIVector(cgRect: rect), forKey: "inputExtent")
    filter?.setValue(count, forKey: "inputCount")
    filter?.setValue(scale, forKey: "inputScale")
//    filter?.setValue(0, forKey: "maximumStop")
//    filter?.setValue(100, forKey: "minimumStop")
    return filter?.outputImage
}

func histogramDisplayFilter(_ input: CIImage, height: Float = 100, highLimit: Float = 50.0, lowLimit: Float = 0.0) -> CIImage?
{
    let filter = CIFilter(name:"CIHistogramDisplayFilter")
    filter?.setValue(input,     forKey: kCIInputImageKey)
    filter?.setValue(height,    forKey: "inputHeight")
    filter?.setValue(highLimit, forKey: "inputHighLimit")
    filter?.setValue(lowLimit,  forKey: "inputLowLimit")
    return filter?.outputImage
}
fileprivate let ciContext = CIContext()

struct HistogramView: View {
    var histogramImage: CIImage?
//    var data: Array<SIMD4<Float32>>?
    var data: (red: [Float], green: [Float], blue: [Float], alpha:[Float])?
//    var data3: (red: [UInt], green: [UInt], blue: [UInt], alpha:[UInt])?
    
    init(ciImage: CIImage? = nil) {
//        self.image = ciImage
        guard let image = ciImage else {
            return
        }
//        let histogramDataImage = areaHistogramFilter(image, rect: image.extent)
//        guard let hdi = histogramDataImage else {
//            return
//        }
        
//        let pixelData = ciContext.readFloat32PixelValues(from: hdi, in: hdi.extent)
        
//        data = pixelData
//        let histogramImage = histogramDisplayFilter(hdi)
//        self.histogramImage = histogramImage
        
        guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
            return
        }
        data = histogramPercentageCalculation(imageRef: cgImage)
    }
    
    var body: some View {
        if let dt = data {
            Chart {
                ForEach(Array(dt.red.enumerated()), id: \.offset) { index, item in
                    let r = item
                    let g = dt.green[index]
                    let b = dt.blue[index]
                    
                    AreaMark(x: .value("x", index), y: .value("y", r), series: .value("red", "R"))
                        .interpolationMethod(.linear)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.red.opacity(0.5))
                    AreaMark(x: .value("x", index), y: .value("y", g), series: .value("green", "G"))
                        .interpolationMethod(.linear)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.green.opacity(0.5))
//
                    AreaMark(x: .value("x", index), y: .value("y", b), series: .value("blue", "B"))
                        .interpolationMethod(.linear)
                        .lineStyle(StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.blue.opacity(0.5))
//                    AreaMark(x: .value("x", index), y: .value("y", a), series: .value("alpha", "A"))
//                        .interpolationMethod(.linear)
//                        .lineStyle(StrokeStyle(lineWidth: 1))
//                        .foregroundStyle(Color.yellow.opacity(0.5))
                }
            }
            .chartYScale(domain: 0...1)
            .frame(width: 250, height: 100)
        }
    }
}

//#Preview {
//    HistogramView()
//}
