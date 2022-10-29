import Foundation
import ShellOut

public protocol ParallelsCommandRunner {
    @discardableResult
    func runCommand(command: String) throws -> String

    @discardableResult
    func prlctl(_ args: String...) throws -> String

    func prlctlJSON(_ args: String...) throws -> Data
    
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

    func unregisterVM(handle: String) throws {
        try prlctl("unregister", handle)
    }
}

public struct DefaultParallelsCommandRunner: ParallelsCommandRunner {
    public init() {}

    public func runCommand(command: String) throws -> String {
        return try shellOut(to: command)
    }

    public func prlctl(_ args: String...) throws -> String {
        return try shellOut(to: "prlctl", arguments: args)
    }

    public func prlctlJSON(_ args: String...) throws -> Data {
        let result = try shellOut(to: "prlctl", arguments: args)

        guard let data = result.data(using: .utf8) else {
            throw InvalidJSONError()
        }
        
        return data
    }
    
    public func prlsrvctl(_ args: String...) throws -> String {
        return try shellOut(to: "prlsrvctl", arguments: args)
    }
    
    struct InvalidJSONError: Error{}
}
