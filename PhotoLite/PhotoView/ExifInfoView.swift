//
//  ExifInfoView.swift
//  PhotoView
//
//  Created by Suxin on 2024/5/16.
//

import SwiftUI
import Foundation

struct ExifInfoView: View {
    @Binding var data: NSDictionary?
    
    func fileSizeFormat(size: Int64) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useGB, .useMB, .useKB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: size)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let dt = data {

                    if let v1 = dt["Make"], let v2 = dt["Model"] {
                        Text("\(v1) \(v2)")
                            .foregroundStyle(.white)
                            .padding(.all, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .border(width: 1, edges: [.bottom], color: .gray)

                    }
                
                
                VStack {
                    if let value = dt["LensModel"] {
                        Text("\(value)")
                            .foregroundStyle(.white)
                            .padding(.vertical, 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        if let height = dt["PixelHeight"], let width = dt["PixelWidth"] {
                            Text("\(height)×\(width)")
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if let size = dt["FileSize"] {

                            if let num = size as? Int64 {
                                Text("\(fileSizeFormat(size: num))")
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
//

                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.all, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .border(width: 1, edges: [.bottom], color: .gray)
                
                
                HStack(alignment: .center) {
                    if let value = dt["ISOSpeedRatings"] {
                        if let arr = value as! Array<Int32>? {
                            Text("ISO\(arr[0])")
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    if let value = dt["FocalLength"] {
                        Text("\(value)mm")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    if let value = dt["FNumber"] {
                        Text("ƒ\(value)")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if let value = dt["ExposureTime"] {
                        let string = String(describing: value)
                        let num = Int(round(1 / (Float(string) ?? 1)))
                        Text("1/\(num)s")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.all, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            } else {
                Text("empty")
            }
        }
//        .padding(.all, 16)
        .frame(width: 250)
        .background(Color.gray.opacity(0.8))
        .cornerRadius(5)
        
    }
}

#Preview {
    @State var data:NSDictionary? = [
        "Make": "xx",
        "Model": "xx",
        "FocalLength": "12",
        "FNumber": "3.0",
        "ExposureTime": "3.0",
        "LensModel": "xxxxx",
        "ISOSpeedRatings": [100]
    ]
    return ExifInfoView(data: $data)
}

//struct PhotoThumbnail_Previews: PreviewProvider {
//    static var data:NSDictionary? = ["Make": "xx"]
//    static var previews: some View {
//            ExifInfoView(data: data)
//    }
//}
