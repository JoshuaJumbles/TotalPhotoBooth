import Foundation
import UIKit
@testable import TotalPhotoBooth

final class FakePhotoLibrarySaver: PhotoLibrarySaverProtocol {
    private(set) var savedImages: [UIImage] = []
    var saveError: Error?

    func save(image: UIImage) async throws {
        if let saveError {
            throw saveError
        }
        savedImages.append(image)
    }
}
