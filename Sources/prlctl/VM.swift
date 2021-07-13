import Foundation

public enum VMStatus: String, Codable {
    case running
    case stopped
}

public protocol VMProtocol {
    var uuid: String { get }
    var name: String { get }
}

public struct VM: VMProtocol, Codable {
    public let uuid: String
    public let name: String
    let status: VMStatus
    let ip_configured: String

    var asRunningVM: RunningVM? {
        guard status == .running else {
            return nil
        }

        return RunningVM(uuid: uuid, name: name, ipAddress: ip_configured)
    }

    var asStoppedVM: StoppedVM? {
        guard status == .stopped else {
            return nil
        }

        return StoppedVM(uuid: uuid, name: name)
    }
}

public struct StoppedVM: VMProtocol {
    public let uuid: String
    public let name: String

    private let runner: ParallelsCommandRunner

    init(uuid: String, name: String, runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) {
        self.uuid = uuid
        self.name = name
        self.runner = runner
    }

    public func start() throws {
        try runner.runCommand(components: ["prlctl", "start", uuid, "--wait"])
    }

    public func clone(as newName: String) throws {
        try runner.runCommand(components: ["prlctl", "clone", uuid, "--name", newName])
    }
}

public struct RunningVM: VMProtocol {
    public let uuid: String
    public let name: String
    public let ipAddress: String

    private let runner: ParallelsCommandRunner

    init(uuid: String, name: String, ipAddress: String, runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) {
        self.uuid = uuid
        self.name = name
        self.ipAddress = ipAddress
        self.runner = runner
    }

    public var hasIpAddress: Bool {
        return ipAddress != "-"
    }
}

extension RunningVM {
    public func shutdown(immediately: Bool = false) throws {
        if immediately {
            try runner.runCommand(components: ["prlctl", "stop", uuid, "--fast"])
        } else {
            try runner.runCommand(components: ["prlctl", "stop", uuid])
        }
    }

    @discardableResult
    public func runCommand(_ command: String, as user: User = .root) throws -> String {
        if user == .root {
            return try runner.runCommand(components: ["prlctl", "exec", self.uuid, command])
        } else {
            let command = "su - $USERNAME -c '$COMMAND'"
                .replacingOccurrences(of: "$USERNAME", with: user.name)
                .replacingOccurrences(of: "$COMMAND", with: command)
            return try runner.runCommand(components: ["prlctl", "exec", self.uuid, command])
        }
    }
}
