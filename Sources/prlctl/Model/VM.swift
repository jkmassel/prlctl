import Foundation

public enum VMStatus: String, Codable {
    case running
    case stopped
    case packaged
    case suspended
    case invalid
    case starting
    case stopping
    case resuming
}

public protocol VMProtocol {
    var uuid: String { get }
    var name: String { get }
}

extension VMProtocol {

    /// Delete this VM
    public func delete(runner: ParallelsCommandRunner = .default) throws {
        // It's ok if trying to stop the VM fails – it might already be stopped
        try? runner.stopVM(handle: uuid, fast: true)

        try runner.deleteVM(handle: uuid)
    }

    /// Unregister this VM from Parallels without deleting any files on disk
    public func unregister(runner: ParallelsCommandRunner = .default) throws {
        try runner.unregisterVM(handle: uuid)
    }
}

public struct CodableVM: VMProtocol, Codable {
    public let uuid: String
    public let name: String
    public let status: VMStatus
    let ipAddress: String

    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case status

        case ipAddress = "ip_configured"
    }
}

public struct VM: VMProtocol {
    public let uuid: String
    public let name: String
    public let status: VMStatus
    let ipAddress: String

    init(uuid: String, name: String, status: VMStatus, ipAddress: String) {
        self.uuid = uuid
        self.name = name
        self.status = status
        self.ipAddress = ipAddress
    }

    init(vm: CodableVM, details: VMDetails) {
        self.uuid = vm.uuid
        self.name = vm.name
        self.ipAddress = vm.ipAddress
        self.status = details.isPackage ? .packaged : vm.status
    }

    public var isStartingVM: Bool {
        status == .starting
    }

    public func asStartingVM() -> StartingVM? {
        guard isStartingVM else {
            return nil
        }

        return StartingVM(uuid: uuid, name: name)
    }

    public var isStoppingVM: Bool {
        status == .stopping
    }

    public func asStoppingVM() -> StoppingVM? {
        guard isStoppingVM else {
            return nil
        }

        return StoppingVM(uuid: uuid, name: name)
    }
}

// MARK: Conversion Methods
// These are in the same order as the sample data on the filesystem in Tests/prlctlTests/resources
extension VM {
    public var isInvalidVM: Bool {
        status == .invalid
    }

    public func asInvalidVM() -> InvalidVM? {
        guard isInvalidVM else {
            return nil
        }

        return InvalidVM(uuid: uuid, name: name)
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

    public var isResuming: Bool {
        status == .resuming
    }

    public func asResumingVM() -> ResumingVM? {
        guard isResuming else {
            return nil
        }

        return ResumingVM(uuid: uuid, name: name)
    }

    public var isRunningVM: Bool {
        status == .running
    }

    public func asRunningVM() -> RunningVM? {
        guard isRunningVM else {
            return nil
        }

        return RunningVM(uuid: uuid, name: name, ipAddress: ipAddress)
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

    public var isSuspendedVM: Bool {
        status == .suspended
    }

    public func asSuspendedVM() -> SuspendedVM? {
        guard isSuspendedVM else {
            return nil
        }

        return SuspendedVM(uuid: uuid, name: name)
    }
}

extension VM: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uuid == rhs.uuid
    }
}

public struct SuspendedVM: VMProtocol {
    public let uuid: String
    public let name: String
}

public struct InvalidVM: VMProtocol {
    public let uuid: String
    public let name: String
}

public struct StartingVM: VMProtocol {
    public let uuid: String
    public let name: String
}

public struct StoppingVM: VMProtocol {
    public let uuid: String
    public let name: String
}

public struct ResumingVM: VMProtocol {
    public let uuid: String
    public let name: String
}

typealias CodableVMSnapshotList = [String: CodableVMSnapshot]

struct CodableVMSnapshot: Codable {
    let name: String
}

public struct VMSnapshot {
    let uuid: String
    let name: String
}
