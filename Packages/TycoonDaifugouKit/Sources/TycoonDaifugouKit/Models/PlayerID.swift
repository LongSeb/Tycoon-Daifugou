import Foundation

/// A distinct identity for a player. Wrapping UUID prevents accidental
/// conflation with other ID types at the type-system level.
public struct PlayerID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let value: UUID

    public init(_ value: UUID = UUID()) {
        self.value = value
    }

    public var description: String { value.uuidString }
}
