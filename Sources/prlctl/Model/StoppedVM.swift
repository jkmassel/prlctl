import Foundation

public struct StoppedVM: VMProtocol {
    public let uuid: String
    public let name: String

    init(uuid: String, name: String) {
        self.uuid = uuid
        self.name = name
    }

    /// Start the VM
    public func start(runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) throws {
        try runner.prlctl("start", uuid, "--wait")
    }

    /// Clone the VM
    ///
    /// - Parameters:
    ///     - as: The name to use for the new VM
    ///     - fast: Whether to use the Parallels linked clone feature to speed up VM cloning (on by default)
    public func clone(as newName: String, fast: Bool = true, runner: ParallelsCommandRunner = .default) throws {
        if fast {
            try runner.prlctl("clone", uuid, "--name", newName, "--linked")
        } else {
            try runner.prlctl("clone", uuid, "--name", newName)
        }
    }

    /// Clean up the VM by removing all snapshots.
    ///
    /// Snapshots are created by running `clone` in `fast` mode – they need to be cleaned because
    /// otherwise they can take up a lot of disk space.
    public func clean(runner: ParallelsCommandRunner = .default) throws {
        try getSnapshots(runner: runner).forEach {
            try deleteSnapshot($0, runner: runner)
        }
    }

    /// Retrieve a list of snapshots associated with this VM
    public func getSnapshots(runner: ParallelsCommandRunner = .default) throws -> [VMSnapshot] {
        let json = try runner.prlctlJSON("snapshot-list", uuid, "--json")

        return try JSONDecoder()
            .decode(CodableVMSnapshotList.self, from: json)
            .map {
                VMSnapshot(uuid: $0.key, name: $0.value.name)
            }
    }

    /// Delete the given snapshot object from this VM
    public func deleteSnapshot(_ snapshot: VMSnapshot, runner: ParallelsCommandRunner = .default) throws {
        try runner.prlctl("snapshot-delete", uuid, "-i", snapshot.uuid)
    }

    public enum VMOption {
        case cpuCount(_ newCount: Int)
        case memorySize(_ megabytes: Int)
        case hypervisorType(_ type: HypervisorType)
        case networkType(_ type: NetworkType, interface: String = "net0")
        case smartMount(_ state: State)
        case sharedClipboard(_ state: State)
        case sharedCloud(_ state: State)
        case sharedProfile(_ state: State)
        case sharedCamera(_ state: State)
        case sharedBluetooth(_ state: State)
        case sharedSmartcard(_ state: State)
        case isolateVM(_ state: State)
        case withoutSoundDevice(handle: String = "sound0")
        case withoutCDROMDevice(handle: String = "cdrom0")
    }

    public enum State: String {
        case on
        case off
    }

    public enum HypervisorType: String {
        case parallels
        case apple
    }

    public enum NetworkType: String {
        case shared = "shared"
        case bridged = "bridged"
        case hostOnly = "host-only"
    }

    // swiftlint:disable cyclomatic_complexity
    public func set(_ option: VMOption, runner: ParallelsCommandRunner = .default) throws {
        switch option {
        case .cpuCount(let newCount):
            try runner.prlctl("set \(uuid) --cpus \(newCount)")
        case .memorySize(let megabytes):
            try runner.prlctl("set \(uuid) --memsize \(megabytes)")
        case .hypervisorType(let type):
            try runner.prlctl("set \(uuid) --hypervisor-type \(type)")
        case .networkType(let type, let interface):
            try runner.prlctl("set \(uuid) --device-set \(interface) --type \(type.rawValue)")
        case .smartMount(let state):
            try runner.prlctl("set \(uuid) --smart-mount \(state.rawValue)")
        case .sharedClipboard(let state):
            try runner.prlctl("set \(uuid) --shared-clipboard \(state.rawValue)")
        case .sharedCloud(let state):
            try runner.prlctl("set \(uuid) --shared-cloud \(state.rawValue)")
        case .sharedProfile(let state):
            try runner.prlctl("set \(uuid) --shared-profile \(state.rawValue)")
        case .sharedCamera(let state):
            try runner.prlctl("set \(uuid) --auto-share-camera \(state.rawValue)")
        case .sharedBluetooth(let state):
            try runner.prlctl("set \(uuid) --auto-share-bluetooth \(state.rawValue)")
        case .sharedSmartcard(let state):
            try runner.prlctl("set \(uuid) --auto-share-smart-card \(state.rawValue)")
        case .isolateVM(let state):
            try runner.prlctl("set \(uuid) --isolate-vm \(state.rawValue)")
        case .withoutSoundDevice(let handle):
            try runner.prlctl("set \(uuid) --device-del \(handle)")
        case .withoutCDROMDevice(let handle):
            try runner.prlctl("set \(uuid) --device-del \(handle)")
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
