import Foundation

protocol PhotoSessionRepositoryProtocol {
    func save(_ session: PhotoSession) async throws
    func fetchAll() async throws -> [PhotoSession]
}
