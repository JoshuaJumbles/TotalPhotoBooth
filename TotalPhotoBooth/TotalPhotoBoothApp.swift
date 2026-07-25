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
    private let cameraService: CameraCaptureServiceProtocol
    private let imageService: CompositeImageRendererService
    
    init() {
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: PhotoSessionModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        repository = SwiftDataPhotoSessionRepository(modelContainer: modelContainer)
        imageService = CompositeImageRendererService()
        
#if targetEnvironment(simulator)
        cameraService = SimulatedCameraCaptureService()
#else
        cameraService = AVFoundationCameraCaptureService()
#endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(
                sessionConfigurationViewModel: SessionConfigurationViewModel(
                    repository: repository,
                    cameraService: cameraService,
                    imageService: imageService
                ),
                reportViewModel: ReportViewModel(repository: repository)
            )
        }
    }
}
