//
//  todoappApp.swift
//  todoapp
//

import SwiftUI
import SwiftData

@main
struct todoappApp: App {
    @StateObject private var themeManager = ThemeManager()

    var sharedModelContainer: ModelContainer = {
        do {
            // ウィジェットと共有する場所（App Group）に置く。以前のデータは初回だけ写す
            return try SharedStore.makeContainer(migrateLegacyStore: true)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if CommandLine.arguments.contains("-ds-catalog") {
                DesignSystemCatalog()
            } else {
                ContentView()
                    .environmentObject(themeManager)
            }
            #else
            ContentView()
                .environmentObject(themeManager)
            #endif
        }
        .modelContainer(sharedModelContainer)
    }
}
