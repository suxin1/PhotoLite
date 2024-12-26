import Accelerate

func histogramCalculation(imageRef: CGImage) -> (red: [UInt], green: [UInt], blue: [UInt], alpha:[UInt])
{

    let imgProvider: CGDataProvider = imageRef.dataProvider!
    let imgBitmapData: CFData = imgProvider.data!

    var imgBuffer = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(imgBitmapData)),
        height: vImagePixelCount(imageRef.height),
        width: vImagePixelCount(imageRef.width),
        rowBytes: imageRef.bytesPerRow)


    // bins: zero = red, green = one, blue = two, alpha = three
    var histogramBinZero = [vImagePixelCount](repeating: 0, count: 256)
    var histogramBinOne = [vImagePixelCount](repeating: 0, count: 256)
    var histogramBinTwo = [vImagePixelCount](repeating: 0, count: 256)
    var histogramBinThree = [vImagePixelCount](repeating: 0, count: 256)

    histogramBinZero.withUnsafeMutableBufferPointer { zeroPtr in
        histogramBinOne.withUnsafeMutableBufferPointer { onePtr in
            histogramBinTwo.withUnsafeMutableBufferPointer { twoPtr in
                histogramBinThree.withUnsafeMutableBufferPointer { threePtr in

                    var histogramBins = [zeroPtr.baseAddress, onePtr.baseAddress,
                                         twoPtr.baseAddress, threePtr.baseAddress]

                    histogramBins.withUnsafeMutableBufferPointer { histogramBinsPtr in
                        let error =  vImageHistogramCalculation_ARGB8888(
                            &imgBuffer,
                            histogramBinsPtr.baseAddress!,
                            vImage_Flags(kvImageNoFlags)
                        )

                        guard error == kvImageNoError else {
                            fatalError("Error calculating histogram: \(error)")
                        }
                    }
                }
            }
        }
    }


    return (histogramBinZero, histogramBinOne, histogramBinTwo, histogramBinThree)
}


func histogramPercentageCalculation(imageRef: CGImage) -> (red: [Float], green: [Float], blue: [Float], alpha:[Float])
{

    let imgProvider: CGDataProvider = imageRef.dataProvider!
    let imgBitmapData: CFData = imgProvider.data!

    var imgBuffer = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(imgBitmapData)),
        height: vImagePixelCount(imageRef.height),
        width: vImagePixelCount(imageRef.width),
        rowBytes: imageRef.bytesPerRow)


    // bins: zero = red, green = one, blue = two, alpha = three
    var histogramBinZero = [vImagePixelCount](repeating: 0, count: 256)
    var histogramBinOne = [vImagePixelCount](repeating: 0, count: 256)
    var histogramBinTwo = [vImagePixelCount](repeating: 0, count: 256)
    var histogramBinThree = [vImagePixelCount](repeating: 0, count: 256)

    histogramBinZero.withUnsafeMutableBufferPointer { zeroPtr in
        histogramBinOne.withUnsafeMutableBufferPointer { onePtr in
            histogramBinTwo.withUnsafeMutableBufferPointer { twoPtr in
                histogramBinThree.withUnsafeMutableBufferPointer { threePtr in

                    var histogramBins = [zeroPtr.baseAddress, onePtr.baseAddress,
                                         twoPtr.baseAddress, threePtr.baseAddress]

                    histogramBins.withUnsafeMutableBufferPointer { histogramBinsPtr in
                        let error =  vImageHistogramCalculation_ARGB8888(
                            &imgBuffer,
                            histogramBinsPtr.baseAddress!,
                            vImage_Flags(kvImageNoFlags)
                        )

                        guard error == kvImageNoError else {
                            fatalError("Error calculating histogram: \(error)")
                        }
                    }
                }
            }
        }
    }

    let totalPixel: Float = Float(UInt32(imageRef.height) * UInt32(imageRef.width)) / 30
    
    
    let histogramBinZeroUInt32 = histogramBinZero.map {Float($0)}
    let histogramBinOneUInt32 = histogramBinOne.map {Float($0)}
    let histogramBinTwoUInt32 = histogramBinTwo.map {Float($0)}
    let histogramBinThreeUInt32 = histogramBinThree.map {Float($0)}
    
    let histogramBinZeroFloat = vDSP.divide(histogramBinZeroUInt32, totalPixel)
    let histogramBinOneFloat = vDSP.divide(histogramBinOneUInt32, totalPixel)
    let histogramBinTwoFloat = vDSP.divide(histogramBinTwoUInt32, totalPixel)
    let histogramBinThreeFloat = vDSP.divide(histogramBinThreeUInt32, totalPixel)
    
    return (histogramBinZeroFloat, histogramBinOneFloat, histogramBinTwoFloat, histogramBinThreeFloat)
}

