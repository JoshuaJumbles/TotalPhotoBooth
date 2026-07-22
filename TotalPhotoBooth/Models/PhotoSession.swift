import Foundation

struct PhotoSession: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date

    init(id: UUID = UUID(), timestamp: Date = .now) {
        self.id = id
        self.timestamp = timestamp
    }
}
