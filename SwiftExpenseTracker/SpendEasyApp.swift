//
//  SpendEasyApp.swift
//  SpendEasy
//
//  Created by Om Panjwani on 21/11/25.
//

import SwiftUI

@main
struct SpendEasyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
