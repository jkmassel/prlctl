import Foundation

public struct Parallels {

    private let runner: ParallelsCommandRunner

    public init() {
        self.init(runner: DefaultParallelsCommandRunner())
    }

    public init(runner: ParallelsCommandRunner) {
        self.runner = runner
        self.serviceControl = ParallelsService(runner: runner)
    }

    let serviceControl: ParallelsService

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

    public func lookupRunningVMs() throws -> [RunningVM] {
        try lookupAllVMs().compactMap { $0.asRunningVM() }
    }

    public func lookupStoppedVMs() throws -> [StoppedVM] {
        try lookupAllVMs().compactMap { $0.asStoppedVM() }
    }

    public func lookupPackagedVMs() throws -> [PackagedVM] {
        try lookupAllVMs().compactMap { $0.asPackagedVM() }
    }

    public func lookupSuspendedVMs() throws -> [SuspendedVM] {
        try lookupAllVMs().compactMap { $0.asSuspendedVM() }
    }

    public func lookupResumingVMs() throws -> [ResumingVM] {
        try lookupAllVMs().compactMap { $0.asResumingVM() }
    }

    public func lookupInvalidVMs() throws -> [InvalidVM] {
        let allVms = try lookupAllVMs()
        return allVms.compactMap { $0.asInvalidVM() }
    }

    /// Returns all VMs that are currently booting
    public func lookupStartingVMs() throws -> [StartingVM] {
        try lookupAllVMs().compactMap { $0.asStartingVM() }
    }

    /// Returns all VMs that are currently shutting down
    public func lookupStoppingVMs() throws -> [StoppingVM] {
        try lookupAllVMs().compactMap { $0.asStoppingVM() }
    }

    public func lookupVM(named handle: String) throws -> VM? {
        guard let vm = try lookupAllVMs().filter({ $0.uuid == handle || $0.name == handle }).first else {
            return nil
        }

        return vm
    }

    func lookupAllVMInfo() throws -> [String: CodableVM] {
        let json = try runner.prlctlJSON("list", "--json", "--full", "--all")

        return try JSONDecoder().decode([CodableVM].self, from: json).reduce([String : CodableVM](), {
            var dict = $0
            dict[$1.uuid] = $1
            return dict
        })
    }

    func lookupAllVMDetails() throws -> [String: VMDetails] {
        let json = try runner.prlctlJSON("list", "--json", "--full", "--all", "--info")

        return try JSONDecoder().decode([VMDetails].self, from: json).reduce([String: VMDetails](), {
            var dict = $0
            dict[$1.uuid] = $1
            return dict
        })
    }

    func registerVM(at url: URL) throws {
        try runner.prlctl("register", url.path, "--preserve-uuid=no")
    }

    func unregisterVM(handle: String) throws {
        try runner.unregisterVM(handle: handle)
    }

    @discardableResult
    public func importVM(at url: URL) throws -> VM? {
        let previousVMs = try lookupAllVMs()
        try registerVM(at: url)
        let currentVMs = try lookupAllVMs()

        /// Return just the VM that didn't exist before
        return currentVMs.filter { !previousVMs.contains($0) }.first
    }
}
