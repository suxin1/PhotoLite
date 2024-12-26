//
//  PhotoLiteApp.swift
//  PhotoLite
//
//  Created by Suxin on 2024/12/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct PhotoLiteApp: App {
    var body: some Scene {
        DocumentGroup(editing: .itemDocument, migrationPlan: PhotoLiteMigrationPlan.self) {
            ContentView()
        }
    }
}

extension UTType {
    static var itemDocument: UTType {
        UTType(importedAs: "com.example.item-document")
    }
}

struct PhotoLiteMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] = [
        PhotoLiteVersionedSchema.self,
    ]

    static var stages: [MigrationStage] = [
        // Stages of migration between VersionedSchema, if required.
    ]
}

struct PhotoLiteVersionedSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Item.self,
    ]
}
