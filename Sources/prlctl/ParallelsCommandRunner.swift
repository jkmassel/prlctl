import Foundation
import ShellOut

public protocol ParallelsCommandRunner {
    @discardableResult
    func runCommand(command: String) throws -> String

    @discardableResult
    func runCommand(components: [String]) throws -> String

    @discardableResult
    func prlctl(_ args: String...) throws -> String

    @discardableResult
    func prlsrvctl(_ args: String...) throws -> String
}

extension ParallelsCommandRunner {

    func stopVM(handle: String, fast: Bool) throws {
        if fast {
            try prlctl("stop", handle, "--fast")
        } else {
            try prlctl("stop", handle)
        }
    }

    func deleteVM(handle: String) throws {
        try prlctl("delete", handle)
    }
}

public struct DefaultParallelsCommandRunner: ParallelsCommandRunner {
    public init() {}

    public func runCommand(command: String) throws -> String {
        return try shellOut(to: command)
    }

    public func runCommand(components: [String]) throws -> String {
        try runCommand(command: components.joined(separator: " "))
    }

    public func prlctl(_ args: String...) throws -> String {
        return try shellOut(to: "prlctl", arguments: args)
    }

    public func prlsrvctl(_ args: String...) throws -> String {
        return try shellOut(to: "prlsrvctl", arguments: args)
    }
}
