import Foundation

public struct User: Equatable {
    public let name: String
    public static let root = User(named: "root")

    public init(named name: String) {
        self.name = name
    }
}
