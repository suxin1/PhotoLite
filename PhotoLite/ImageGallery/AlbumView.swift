//
//  GridView.swift
//  PhotoView
//
//  Created by Suxin on 2024/3/22.


import SwiftUI

struct AlbumView: View {
    var dataModel: AlbumDataModel
    
    private static let initialColumns = 6
    
    @State private var isAddingPhoto = false
    
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    @State private var columnNums = initialColumns
    
    private var columnsTitle:String {
        gridColumns.count > 1 ? "\(gridColumns.count) Columns" : "1 Column"
    }
    
    func addPhoto() {
        
    }
    
    var body: some View {
        ZStack {
            if (dataModel.photos.count != 0) {
                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(dataModel.photos, id: \.self) { item in
                            GeometryReader { geo in
                                NavigationLink(value: item) {
                                    PhotoThumbnail(size: geo.size.width, item: item)
                                }
                                .buttonStyle(.plain)
                            }
                            .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding()
                }
            } else {
                Text("没有发现图片文件")
            }
        }
        .sheet(isPresented: $isAddingPhoto, onDismiss: addPhoto) {
//            PhotosPicker(selection: $selectedPhoto, matching: .images) {
//                Text("Select Photos")
//            }
        }
        .toolbar {
//            ToolbarItem(placement: .automatic) {
//                Button(isEditing ? "Done" : "Edit") {
//                    withAnimation {
//                        isEditing.toggle()
//                    }
//                }
//            }
            
//            ToolbarItem(placement: .automatic) {
//                Button {
//                    isAddingPhoto = true
//                } label: {
//                    Image(systemName: "plus")
//                }
////                .disabled(isEditing)
//            }
        }
    }
}

#Preview {
    AlbumView(dataModel: AlbumDataModel(with: URL(fileURLWithPath: "/Users/suxin/Pictures/", isDirectory: true))).frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
}
