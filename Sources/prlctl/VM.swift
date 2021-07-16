import Foundation
import Network

public enum VMStatus: String, Codable {
    case running
    case stopped
    case packaged
    case suspended
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

    public init(from vm: VM) {
        self.uuid = vm.uuid
        self.name = vm.name
        self.status = vm.status
        self.ip_configured = vm.ip_configured
    }

    public var isRunningVM: Bool {
        status == .running
    }

    public func asRunningVM() -> RunningVM? {
        guard isRunningVM else {
            return nil
        }

        return RunningVM(uuid: uuid, name: name, ipAddress: ip_configured)
    }

    public var isStoppedVM: Bool {
        status == .stopped
    }

    public func asStoppedVM() -> StoppedVM? {
        guard isStoppedVM else {
            return nil
        }

        return StoppedVM(uuid: uuid, name: name)
    }

    public var isPackagedVM: Bool {
        status == .packaged
    }

    public func asPackagedVM() -> PackagedVM? {
        guard isPackagedVM else {
            return nil
        }

        return PackagedVM(uuid: uuid, name: name)
    }
}

extension VM: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

public struct PackagedVM: VMProtocol {
    public let uuid: String
    public let name: String

    private let runner: ParallelsCommandRunner

    public init(vm: PackagedVM) {
        self.uuid = vm.uuid
        self.name = vm.name

        self.runner = vm.runner
    }

    init(uuid: String, name: String, runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) {
        self.uuid = uuid
        self.name = name
        self.runner = runner
    }

    public func unpack() throws -> StoppedVM {
        try runner.runCommand(components: ["prlctl", "unpack", uuid])
        return StoppedVM(uuid: uuid, name: name, runner: runner)
    }
}

public struct StoppedVM: VMProtocol {
    public let uuid: String
    public let name: String

    private let runner: ParallelsCommandRunner

    public init(vm: StoppedVM) {
        self.uuid = vm.uuid
        self.name = vm.name
        self.runner = vm.runner
    }

    init(uuid: String, name: String, runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) {
        self.uuid = uuid
        self.name = name
        self.runner = runner
    }

    /// Start the VM
    public func start() throws {
        try runner.runCommand(components: ["prlctl", "start", uuid, "--wait"])
    }

    /// Clone the VM
    ///
    /// - Parameters:
    ///     - as: The name to use for the new VM
    ///     - fast: Whether to use the Parallels linked clone feature to speed up VM cloning (on by default)
    public func clone(as newName: String, fast: Bool = true) throws {
        if fast {
            try runner.runCommand(components: ["prlctl", "clone", uuid, "--name", newName, "--linked"])
        } else {
            try runner.runCommand(components: ["prlctl", "clone", uuid, "--name", newName])
        }
    }

    /// Clean up the VM by removing all snapshots.
    ///
    /// Snapshots are created by running `clone` in `fast` mode – they need to be cleaned because otherwise they can take up a lot of disk space.
    public func clean() throws {
        try getSnapshots().forEach {
            try deleteSnapshot($0)
        }
    }

    /// Retrieve a list of snapshots associated with this VM
    public func getSnapshots() throws -> [VMSnapshot] {
        let json = try runner.runCommand(components: ["prlctl", "snapshot-list", uuid, "--json"]).data(using: .utf8)!
        return try JSONDecoder()
            .decode(CodableVMSnapshotList.self, from: json)
            .map {
                VMSnapshot(uuid: $0.key, name: $0.value.name)
            }
    }

    /// Delete the given snapshot object from this VM
    public func deleteSnapshot(_ snapshot: VMSnapshot) throws {
        try runner.runCommand(components: ["prlctl", "snapshot-delete", uuid, "-i", snapshot.uuid])
    }

    /// Delete this VM
    public func delete() throws {
        try runner.runCommand(components: ["prlctl", "delete", uuid])
    }
}

public struct RunningVM: VMProtocol {

    public let uuid: String
    public let name: String
    public let ipAddress: String

    private let runner: ParallelsCommandRunner

    public init(vm: RunningVM) {
        self.uuid = vm.uuid
        self.name = vm.name
        self.ipAddress = vm.ipAddress

        self.runner = vm.runner
    }

    init(uuid: String, name: String, ipAddress: String, runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) {
        self.uuid = uuid
        self.name = name
        self.ipAddress = ipAddress
        self.runner = runner
    }

    public var hasIpAddress: Bool {
        return ipAddress != "-"
    }

    public var hasIpV4Address: Bool {
        IPv4Address(ipAddress) != nil
    }

    public var hasIpV6Address: Bool {
        IPv6Address(ipAddress) != nil
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

typealias CodableVMSnapshotList = [String: CodableVMSnapshot]

struct CodableVMSnapshot: Codable {
    let name: String
}

public struct VMSnapshot {
    let uuid: String
    let name: String
}
