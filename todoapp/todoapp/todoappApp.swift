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
        let schema = Schema([
            TodoGroup.self,
            SubGroup.self,
            TodoTask.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
