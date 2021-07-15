import Foundation

public enum VMStatus: String, Codable {
    case running
    case stopped
    case packaged
}

public protocol VMProtocol {
    var uuid: String { get }
    var name: String { get }
}

public struct CodableVM: VMProtocol, Codable {
    public let uuid: String
    public let name: String
    public let status: VMStatus
    let ip_configured: String
}

public struct VM: VMProtocol {
    public let uuid: String
    public let name: String
    let status: VMStatus
    let ip_configured: String

    init(vm: CodableVM) {
        self.uuid = vm.uuid
        self.name = vm.name
        self.status = vm.status
        self.ip_configured = vm.ip_configured
    }

    init(vm: CodableVM, details: VMDetails) {
        self.uuid = vm.uuid
        self.name = vm.name
        self.ip_configured = vm.ip_configured
        self.status = details.isPackage ? .packaged : vm.status
    }

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

    var asPackagedVM: PackagedVM? {
        guard status == .packaged else {
            return nil
        }

        return PackagedVM(uuid: uuid, name: name)
    }
}

public struct PackagedVM: VMProtocol {
    public let uuid: String
    public let name: String

    private let runner: ParallelsCommandRunner

    init(uuid: String, name: String, runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) {
        self.uuid = uuid
        self.name = name
        self.runner = runner
    }

    func unpack() throws -> StoppedVM {
        try runner.runCommand(components: ["prlctl", "unpack", uuid])
        return StoppedVM(uuid: uuid, name: name, runner: runner)
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

    public func clone(as newName: String, fast: Bool = false) throws {
        if fast {
            try runner.runCommand(components: ["prlctl", "clone", uuid, "--name", newName, "--linked"])
        } else {
            try runner.runCommand(components: ["prlctl", "clone", uuid, "--name", newName])
        }
    }

    public func delete() throws {
        try runner.runCommand(components: ["prlctl", "delete", uuid])
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

public struct VMDetails: Codable {
    let uuid: String
    let name: String
    let description: String
    let state: VMStatus
    private let path: String
    private let optimization: VMOptimizationDetails

    var isPackage: Bool {
        path.hasSuffix(".pvmp")
    }

    enum CodingKeys: String, CodingKey {
        case uuid = "ID"
        case name = "Name"
        case description = "Description"
        case state = "State"
        case path = "Home"
        case optimization = "Optimization"
    }

    public struct VMOptimizationDetails: Codable {
        private let fasterVirtualMachine: String
        let hypervisorType: String

        enum CodingKeys: String, CodingKey {
            case fasterVirtualMachine = "Faster virtual machine"
            case hypervisorType = "Hypervisor type"
        }
    }
}
