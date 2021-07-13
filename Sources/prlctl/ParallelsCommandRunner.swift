import Foundation
import ShellOut

public protocol ParallelsCommandRunner {
    @discardableResult
    func runCommand(command: String) throws -> String

    @discardableResult
    func runCommand(components: [String]) throws -> String
}

public struct DefaultParallelsCommandRunner: ParallelsCommandRunner {
    public init() {}

    public func runCommand(command: String) throws -> String {
        return try shellOut(to: command)
    }

    public func runCommand(components: [String]) throws -> String {
        try runCommand(command: components.joined(separator: " "))
    }
}
