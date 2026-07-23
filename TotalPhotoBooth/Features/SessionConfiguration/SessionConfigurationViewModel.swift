import Foundation

@Observable
final class SessionConfigurationViewModel {
    private(set) var sessionCount: Int = 0
    private(set) var isPresentingCustomerExperience: Bool = false
    var errorMessage: String?

    private let repository: PhotoSessionRepositoryProtocol

    init(repository: PhotoSessionRepositoryProtocol) {
        self.repository = repository
    }

    func loadInitialCount() async {
        do {
            sessionCount = try await repository.fetchAll().count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startKioskMode() {
        isPresentingCustomerExperience = true
    }

    func endKioskMode() async {
        isPresentingCustomerExperience = false
        await loadInitialCount()
    }

    func makeCustomerExperienceViewModel() -> CustomerExperienceViewModel {
        CustomerExperienceViewModel(repository: repository)
    }
}
