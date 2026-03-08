import Foundation

struct ExperimentResult: Identifiable, Hashable {
    var id: String { "\(index)-\(commit)" }
    let index: Int
    let commit: String
    let valBPB: Double
    let memoryGB: Double
    let status: ExperimentStatus
    let description: String

    enum ExperimentStatus: String, CaseIterable {
        case keep
        case discard
        case crash

        var label: String {
            rawValue.capitalized
        }
    }
}
