import Foundation

public actor Parallels {

    private let runner: ParallelsCommandRunner

    public init() {
        self.init(runner: DefaultParallelsCommandRunner())
    }

    init(runner: ParallelsCommandRunner) {
        self.runner = runner
        self.serviceControl = ParallelsService(runner: runner)
    }

    let serviceControl: ParallelsService

    public func lookupAllVMs() throws -> [VM] {
        try self.runner.lookupAllVMs()
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
        try self.runner.lookupVM(named: handle)
    }

    /// Start the VM with the given handle (name or UUID)
    ///
    public func startVM(withHandle handle: String, wait: Bool = true) throws {
        try self.runner.startVM(handle: handle, wait: wait)
    }

    /// Shutdown the VM with the given handle (name or UUID)
    ///
    public func shutdownVM(withHandle handle: String, immediately: Bool = false) throws {
        try self.runner.stopVM(handle: handle, fast: immediately)
    }

    /// Clone the VM with the given handle (name or UUID)
    ///
    /// - Parameters:
    ///     - as: The name to use for the new VM
    ///     - fast: Whether to use the Parallels linked clone feature to speed up VM cloning (on by default)
    public func cloneVM(withHandle handle: String, `as` newName: String, fast: Bool = true) throws {
        try self.runner.cloneVM(handle: handle, newName: newName, fast: fast)
    }

    public func unpackVM(withHandle handle: String) throws {
        try runner.unpackVM(handle: handle)
    }

    @discardableResult
    public func runCommand(
        _ command: String,
        onVirtualMachineWithHandle handle: String,
        as user: User = .root
    ) throws -> String {
        var internalCommand = command

        if user != .root {
            internalCommand = "su - '\(user.name)' -c '\(command)'"
        }

        return try self.runner.runCommandOnVM(handle: handle, command: internalCommand)
    }

    /// Clean up the VM by removing all snapshots.
    ///
    /// Snapshots are created by running `clone` in `fast` mode – they need to be cleaned because
    /// otherwise they can take up a lot of disk space.
    public func cleanVM(withHandle handle: String) throws {
        try runner.deleteAllSnapshots(handle: handle)
    }

    public func renameVM(withHandle handle: String, to newName: String) throws {
        try runner.renameVM(handle: handle, newName: newName)
    }

    public func setVMOption(_ option: VMOption, onVirtualMachineWithHandle handle: String) throws {
        try runner.setVMOption(handle: handle, option: option)
    }

    /// Retrieve a list of snapshots associated with this VM
    public func getSnapshotsForVM(withHandle handle: String) throws -> [VMSnapshot] {
        try runner.getSnapshots(handle: handle)
    }

    /// Delete the given snapshot object from this VM
    public func deleteSnapshot(_ snapshot: VMSnapshot) throws {
        try runner.deleteSnapshot(snapshot)
    }

    public func registerVM(at url: URL) throws {
        try runner.registerVM(at: url)
    }

    @available(*, deprecated, message: "Deprecated for API naming alignment", renamed: "unregisterVM(named:)")
    func unregisterVM(handle: String) throws {
        try runner.unregisterVM(handle: handle)
    }

    public func unregisterVM(named handle: String) throws {
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
