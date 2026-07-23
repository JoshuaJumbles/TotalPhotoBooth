//
//  TotalPhotoBoothApp.swift
//  TotalPhotoBooth
//
//  Created by Joshua Jumbles on 7/22/26.
//

import SwiftUI
import SwiftData

@main
struct TotalPhotoBoothApp: App {
    private let repository: SwiftDataPhotoSessionRepository

    init() {
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: PhotoSessionModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        repository = SwiftDataPhotoSessionRepository(modelContainer: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                sessionConfigurationViewModel: SessionConfigurationViewModel(repository: repository),
                reportViewModel: ReportViewModel(repository: repository)
            )
        }
    }
}
