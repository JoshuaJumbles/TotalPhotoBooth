import Foundation
import UIKit

protocol PhotoLibrarySaverProtocol {
    func save(image: UIImage) async throws
}
