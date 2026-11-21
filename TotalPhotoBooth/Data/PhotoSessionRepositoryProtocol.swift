import Foundation

protocol PhotoSessionRepositoryProtocol {
    func save(_ session: PhotoSession) async throws
    func fetchAll() async throws -> [PhotoSession]
    /// Removes every recorded session (Debug Mode's history reset).
    func deleteAll() async throws
}
