import Foundation
import ShellOut

protocol ParallelsCommandRunner {
    @discardableResult
    func runCommand(command: String) throws -> String

    @discardableResult
    func prlctl(_ args: String...) throws -> String

    func prlctlJSON(_ args: String...) throws -> Data

    @discardableResult
    func prlsrvctl(_ args: String...) throws -> String
}

// MARK: Lookup
extension ParallelsCommandRunner {
    public func lookupAllVMs() throws -> [VM] {
        let info    = try lookupAllVMInfo()
        let details = try lookupAllVMDetails()

        return info.compactMap {
            guard let vmDetails = details[$0.key] else {
                return nil
            }

            return VM(vm: $0.value, details: vmDetails)
        }
    }

    public func lookupVM(named handle: String) throws -> VM? {
        guard let vm = try lookupAllVMs().filter({ $0.uuid == handle || $0.name == handle }).first else {
            return nil
        }

        return vm
    }
}

extension ParallelsCommandRunner {

    func lookupAllVMInfo() throws -> [String: CodableVM] {
        let json = try self.prlctlJSON("list", "--json", "--full", "--all")

        return try JSONDecoder().decode([CodableVM].self, from: json).reduce([String: CodableVM](), {
            var dict = $0
            dict[$1.uuid] = $1
            return dict
        })
    }

    func lookupAllVMDetails() throws -> [String: VMDetails] {
        let json = try self.prlctlJSON("list", "--json", "--full", "--all", "--info")

        return try JSONDecoder().decode([VMDetails].self, from: json).reduce([String: VMDetails](), {
            var dict = $0
            dict[$1.uuid] = $1
            return dict
        })
    }

    func startVM(handle: String, wait: Bool) throws {
        if wait {
            try self.prlctl("start", handle, "--wait")
        } else {
            try self.prlctl("start", handle)
        }
    }

    func stopVM(handle: String, fast: Bool) throws {
        if fast {
            try prlctl("stop", handle, "--fast")
        } else {
            try prlctl("stop", handle)
        }
    }

    func renameVM(handle: String, newName: String) throws {
        try self.prlctl("set \(handle) --name \(newName)")
    }

    func cloneVM(handle: String, newName: String, fast: Bool) throws {
        if fast {
            try self.prlctl("clone", handle, "--name", newName, "--linked")
        } else {
            try self.prlctl("clone", handle, "--name", newName)
        }
    }

    func unpackVM(handle: String) throws {
        try self.prlctl("unpack", handle)
    }

    func runCommandOnVM(handle: String, command: String) throws -> String {
        try self.prlctl("exec", handle, command)
    }

    // swiftlint:disable cyclomatic_complexity
    public func setVMOption(handle: String, option: VMOption) throws {
        switch option {
        case .cpuCount(let newCount):
            try self.prlctl("set \(handle) --cpus \(newCount)")
        case .memorySize(let megabytes):
            try self.prlctl("set \(handle) --memsize \(megabytes)")
        case .hypervisorType(let type):
            try self.prlctl("set \(handle) --hypervisor-type \(type)")
        case .networkType(let type, let interface):
            try self.prlctl("set \(handle) --device-set \(interface) --type \(type.rawValue)")
        case .smartMount(let state):
            try self.prlctl("set \(handle) --smart-mount \(state.rawValue)")
        case .sharedClipboard(let state):
            try self.prlctl("set \(handle) --shared-clipboard \(state.rawValue)")
        case .sharedCloud(let state):
            try self.prlctl("set \(handle) --shared-cloud \(state.rawValue)")
        case .sharedProfile(let state):
            try self.prlctl("set \(handle) --shared-profile \(state.rawValue)")
        case .sharedCamera(let state):
            try self.prlctl("set \(handle) --auto-share-camera \(state.rawValue)")
        case .sharedBluetooth(let state):
            try self.prlctl("set \(handle) --auto-share-bluetooth \(state.rawValue)")
        case .sharedSmartcard(let state):
            try self.prlctl("set \(handle) --auto-share-smart-card \(state.rawValue)")
        case .isolateVM(let state):
            try self.prlctl("set \(handle) --isolate-vm \(state.rawValue)")
        case .withoutSoundDevice(let device):
            try self.prlctl("set \(handle) --device-del \(device)")
        case .withoutCDROMDevice(let device):
            try self.prlctl("set \(handle) --device-del \(device)")
        }
    }
    // swiftlint:enable cyclomatic_complexity

    func deleteVM(handle: String) throws {
        try prlctl("delete", handle)
    }

    func registerVM(at path: URL) throws {
        try prlctl("register", path.path, "--preserve-uuid=no")
    }

    func unregisterVM(handle: String) throws {
        try prlctl("unregister", handle)
    }
}

// MARK: Snapshots
extension ParallelsCommandRunner {

    public func deleteAllSnapshots(handle: String) throws {
        for snapshot in try getSnapshots(handle: handle) {
            try self.deleteSnapshot(snapshot)
        }
    }

    func getSnapshots(handle: String) throws -> [VMSnapshot] {
        let json = try self.prlctlJSON("snapshot-list", handle, "--json")

        // If we only get two bytes back, it's `{}`, so we can save a bit of work
        if json.count == 2 {
            return []
        }

        guard let vm = try lookupVM(named: handle) else {
            return []
        }

        return try JSONDecoder()
            .decode(CodableVMSnapshotList.self, from: json)
            .map {
                VMSnapshot(uuid: $0.key, name: $0.value.name, virtualMachineHandle: vm.uuid)
            }
    }

    func deleteSnapshot(_ snapshot: VMSnapshot) throws {
        try self.prlctl("snapshot-delete", snapshot.virtualMachineHandle, "-i", snapshot.uuid)
    }
}

extension ParallelsCommandRunner where Self == DefaultParallelsCommandRunner {
    static var `default`: DefaultParallelsCommandRunner {
        return DefaultParallelsCommandRunner()
    }
}

struct DefaultParallelsCommandRunner: ParallelsCommandRunner {
    public init() {}

    func runCommand(command: String) throws -> String {
        return try shellOut(to: command)
    }

    func prlctl(_ args: String...) throws -> String {
        return try shellOut(to: "prlctl", arguments: args)
    }

    func prlctlJSON(_ args: String...) throws -> Data {
        let result = try shellOut(to: "prlctl", arguments: args)

        guard let data = result.data(using: .utf8) else {
            throw InvalidJSONError()
        }

        return data
    }

    func prlsrvctl(_ args: String...) throws -> String {
        return try shellOut(to: "prlsrvctl", arguments: args)
    }

    struct InvalidJSONError: Error {}
}
