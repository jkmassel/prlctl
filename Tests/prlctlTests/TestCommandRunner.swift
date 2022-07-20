import Foundation
@testable import prlctl

class TestCommandRunner: ParallelsCommandRunner {

    var command: String {
        commands.first ?? ""
    }

    var commands: [String] = []

    private let defaultResponse: String
    private let responses: [String : String]

    /// Used for cases where we're only interested in the output, not the input
    init() {
        self.defaultResponse = ""
        self.responses = [:]
    }

    /// Used for cases where we expect just one command and response
    init(response: String) {
        self.defaultResponse = response
        self.responses = [:]
    }

    /// Used for cases where we expect more than one command and response
    init(responses: [String: String]) {
        self.defaultResponse = ""
        self.responses = responses
    }

    func prlctl(_ args: String...) throws -> String {
        try runCommand(components: ["prlctl"] + args)
    }

    func prlctlJSON(_ args: String...) throws -> Data {
        try runCommand(components: ["prlctl"] + args).data(using: .utf8)!
    }

    func prlsrvctl(_ args: String...) throws -> String {
        try runCommand(components: ["prlsrvctl"] + args)
    }

    func runCommand(components: [String]) throws -> String {
        try runCommand(command: components.joined(separator: " "))
    }

    func runCommand(command: String) throws -> String {
        commands.append(command)

        guard let response = responses[command] else {
            if self.responses.isEmpty {
                return defaultResponse
            }

            throw "No registered response for `\(command)`"
        }

        return response
    }
}
