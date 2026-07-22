import Foundation
@testable import TotalPhotoBooth

final class InMemoryPhotoSessionRepository: PhotoSessionRepositoryProtocol {
    private(set) var sessions: [PhotoSession]
    var saveError: Error?
    var fetchError: Error?

    init(sessions: [PhotoSession] = []) {
        self.sessions = sessions
    }

    func save(_ session: PhotoSession) async throws {
        if let saveError { throw saveError }
        sessions.append(session)
    }

    func fetchAll() async throws -> [PhotoSession] {
        if let fetchError { throw fetchError }
        return sessions
    }
}
