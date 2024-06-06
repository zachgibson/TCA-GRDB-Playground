//
//  TCA_GRDB_PlaygroundApp.swift
//  TCA GRDB Playground
//
//  Created by Zachary Gibson on 6/2/24.
//

import ComposableArchitecture
import GRDB
import SwiftUI

@main
struct TCA_GRDB_PlaygroundApp: App {
    @MainActor
    static let store = Store(initialState: Feature.State()) {
        Feature()
    } withDependencies: {
        do {
            // Create the "Application Support/MyDatabase" directory if needed
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            // Open or create the database
            let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
            $0.defaultDatabaseQueue = try DatabaseQueue(path: databaseURL.path(percentEncoded: false))
        } catch {
            // TODO: Handle error
            fatalError(error.localizedDescription)
        }
    }
    
    init() {
        Self.store.send(.`init`)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: Self.store)
        }
    }
}
