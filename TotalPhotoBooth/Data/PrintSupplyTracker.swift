import Foundation

/// Counts prints against the SELPHY's paper tray and ink cassette so staff
/// can see a refill coming.
///
/// AirPrint never reports "out of paper" or "out of ink" (see
/// `AirPrintConnectionService`), so this is an *estimate*: every print the
/// app hands off counts against both supplies, and staff reset a supply when
/// they physically refill it. Counts persist across launches.
@Observable
final class PrintSupplyTracker {
    enum Supply: String, CaseIterable, Identifiable {
        case paper
        case ink

        var id: Self { self }

        /// Canon CP1500 with KP-108IN packs: the paper cassette holds 18
        /// postcard sheets, and each ink cassette prints 36.
        var capacity: Int {
            switch self {
            case .paper: 18
            case .ink: 36
            }
        }

        var name: String {
            switch self {
            case .paper: "Paper"
            case .ink: "Ink"
            }
        }

        var systemImage: String {
            switch self {
            case .paper: "doc.on.doc"
            case .ink: "drop.fill"
            }
        }

        var refillActionTitle: String {
            switch self {
            case .paper: "Paper Refilled"
            case .ink: "Cassette Replaced"
            }
        }

        fileprivate var defaultsKey: String { "com.totalphotobooth.printsSinceRefill.\(rawValue)" }
    }

    enum Level: Equatable {
        case ok
        case low
        case empty
    }

    /// At or below this many prints left, a supply reads as low.
    static let lowThreshold = 3

    private var printsSinceRefill: [Supply: Int]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        printsSinceRefill = Dictionary(uniqueKeysWithValues: Supply.allCases.map {
            ($0, defaults.integer(forKey: $0.defaultsKey))
        })
    }

    func remaining(_ supply: Supply) -> Int {
        max(0, supply.capacity - (printsSinceRefill[supply] ?? 0))
    }

    func level(_ supply: Supply) -> Level {
        switch remaining(supply) {
        case 0: .empty
        case ...Self.lowThreshold: .low
        default: .ok
        }
    }

    /// Call once per print handed to the printer.
    func recordPrint() {
        for supply in Supply.allCases {
            set(supply, to: (printsSinceRefill[supply] ?? 0) + 1)
        }
    }

    func refilled(_ supply: Supply) {
        set(supply, to: 0)
    }

    private func set(_ supply: Supply, to count: Int) {
        printsSinceRefill[supply] = count
        defaults.set(count, forKey: supply.defaultsKey)
    }
}
