//
//  AlbumSwiperView.swift
//  PhotoView
//
//  Created by Suxin on 2024/3/29.
//

import SwiftUI
import Routing

struct VisualEffect: ViewRepresentable {
    func makeView(context: Self.Context) -> NSView {
        let effect = NSVisualEffectView()
        effect.material = NSVisualEffectView.Material.windowBackground
        return NSVisualEffectView()
    }
    func updateView(_ view: NSView, context: Context) {
    }
}

struct AlbumSwiperView: View {
    
    private let album: AlbumDataModel
    private var index: Int?
    
    @FocusState private var isFocused: Bool
    @State private var current: Int?
    @State private var currentPhoto: Photo?
    @State private var text = 1
    
    init(_ _album: AlbumDataModel, active url: URL) {
        self.album = _album
        
        if let index = album.getPhotoIndex(byUrl: url) {
            self.index = index
        }
    }
    
    func onKeyPress(press: KeyPress) {
        switch press.key {
        case .upArrow:
            print("up")
        case .rightArrow:
            next()
        case .leftArrow:
            previous()
        default:
            break
        }
    }
    
    func next() {
        if let cur = current {
            if (cur < (album.photos.count - 1)) {
                current = cur + 1
                currentPhoto = album.getPhotoByIndex(current)
                refreshCache()
            }
        }
    }
    
    func previous() {
        if let cur = current {
            if (cur > 0) {
                current = cur - 1
                currentPhoto = album.getPhotoByIndex(current)
                refreshCache()
            }
        }
    }
    
    func refreshCache() {
        guard let url = currentPhoto?.url else {
            return
        }
        PhotoCache.shared.generateWeightedList(target: url)
        PhotoCache.shared.sync()
    }
    
    var body: some View {
        ZStack {
            if currentPhoto != nil {
                PhotoView(photo: $currentPhoto)
            } else {
                Text("Photo file not found")
            }
            HStack {
                if (current != 0) {
                    Button {
                        previous()
                    } label: {
                        Image("arrow-left")
                            .resizable()
                            .frame(width: 24, height: 32)
                    }
                    .buttonStyle(.plain)
                }


                Spacer()
                if let cur = current {
                    if (cur < (album.photos.count - 1)) {
                        Button {
                            next()
                        } label: {
                            Image("arrow-right")
                                .resizable()
                                .frame(width: 24, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .onDisappear() {
            PhotoCache.shared.clear()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffect())
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onKeyPress(phases: .up) { press in
            onKeyPress(press: press)
            return .ignored
        }
        .onAppear {
            isFocused = true
            current = index
            currentPhoto = album.getPhotoByIndex(index)
//            currentPhoto = album.getPhotoByIndex(current)
        }

//        .presentedWindowStyle(.hiddenTitleBar)
//        .toolbar(Visibility.automatic, for: ToolbarPlacement.automatic)
        .edgesIgnoringSafeArea(.all)
//        .preferredColorScheme(.dark)
    }
}

//#Preview {
//    AlbumSwiperView()
//}
