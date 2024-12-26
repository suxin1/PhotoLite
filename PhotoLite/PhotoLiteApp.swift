//
//  PhotoViewApp.swift
//  PhotoView
//
//  Created by Suxin on 2024/3/18.


import SwiftUI


class AppConfig: ObservableObject {
    
//    public enum Destination: Codable, Hashable {
//        case directory
//        case photo_view(url: URL)
////        case mtk_view
//    }
    
    @Published var path = NavigationPath()
    @Published var sideNavVisible: NavigationSplitViewVisibility = .automatic
//    @Published var dataModel = AlbumDataModel(byFileUrl: URL(filePath: "/Users/suxin/Photograph/HDR/_DSC4179.jpg"))
    @Published var dataModel = AlbumDataModel()
    @Published var selectDialogOpened = false
    
    static let tempDir = NSTemporaryDirectory()
    
    static let shared = AppConfig()
}

/**
 * select a folder or file to init album
 */
func selectFolderOrFileOnStart() {
    let folderChoosePoint = CGPoint(x: 0, y: 0)
    let folderChooseSize = CGSize(width: 500, height: 600)
    let folderChooseRectangle = CGRect(origin: folderChoosePoint, size: folderChooseSize)
    let folderPicker = NSOpenPanel(contentRect: folderChooseRectangle, styleMask: .utilityWindow, backing: .buffered, defer: true)
    
    folderPicker.canChooseFiles = true
    folderPicker.canChooseDirectories = true
    folderPicker.allowsMultipleSelection = false
    folderPicker.canDownloadUbiquitousContents = true
    folderPicker.canResolveUbiquitousConflicts = true
    
    
    folderPicker.begin { response in
        if response == .OK {
            if let pickedItem = folderPicker.url {
                if pickedItem.isDirectory != nil {
                    AppConfig.shared.dataModel = AlbumDataModel(with: pickedItem)
                } else {
                    AppConfig.shared.dataModel = AlbumDataModel(byFileUrl: pickedItem)
                }
            }
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            AppConfig.shared.sideNavVisible = .detailOnly
            AppConfig.shared.dataModel = AlbumDataModel(byFileUrl: url)
            AppConfig.shared.path.append(Photo(url: url, name: url.lastPathComponent))
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Restore first minimized window if app became active and no window
        // is visible
        if NSApp.windows.compactMap({ $0.isVisible ? Optional(true) : nil }).isEmpty {
             NSApp.windows.first?.makeKeyAndOrderFront(self)
        }
        if (AppConfig.shared.dataModel.photos.count == 0 && !AppConfig.shared.selectDialogOpened) {
            selectFolderOrFileOnStart()
            AppConfig.shared.selectDialogOpened = true
        }
    }
}


@main
struct PhotoViewApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject var appConfig = AppConfig.shared
    
//    init() {
//        if (appConfig.dataModel.photos.count == 0) {
//            selectPhotoFolder()
//        }
//    }
    

    
    var body: some Scene {
        WindowGroup() {
//            NavigationSplitView(columnVisibility: $appConfig.sideNavVisible) {
//                Text("nav bar")
//            } detail: {
                NavigationStack(path: $appConfig.path) {
                    AlbumView(dataModel: appConfig.dataModel)
                    .navigationDestination(for: Photo.self) { photo in
                        AlbumSwiperView(AlbumDataModel(byFileUrl: photo.url, cache: true), active: photo.url)
                    }
                }
            
            .frame(minWidth: 1000, minHeight: 600)
//            .presentedWindowStyle(.hiddenTitleBar)
//            .toolbar(Visibility.hidden, for: ToolbarPlacement.automatic)
            .navigationSplitViewStyle(.prominentDetail)
            .preferredColorScheme(.dark)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .handlesExternalEvents(matching: [])
    }
}


