import Foundation
import SwiftData

@Model
final class PhotoSessionModel {
    var id: UUID
    var timestamp: Date

    init(id: UUID, timestamp: Date) {
        self.id = id
        self.timestamp = timestamp
    }
}

final class SwiftDataPhotoSessionRepository: PhotoSessionRepositoryProtocol {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func save(_ session: PhotoSession) async throws {
        let context = modelContainer.mainContext
        context.insert(PhotoSessionModel(id: session.id, timestamp: session.timestamp))
        try context.save()
    }

    @MainActor
    func fetchAll() async throws -> [PhotoSession] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<PhotoSessionModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let models = try context.fetch(descriptor)
        return models.map { PhotoSession(id: $0.id, timestamp: $0.timestamp) }
    }
}
