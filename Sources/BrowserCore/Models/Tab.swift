import Foundation

/// A single open browser tab. `id` format is "<windowIndex>:<tabIndex>" (1-based), not stable across invocations.
struct Tab: Codable, CustomStringConvertible {
    let id: String
    let title: String
    let url: String
    let active: Bool

    var description: String { "\(id)\(active ? "*" : ""): \(title) (\(url))" }
}
