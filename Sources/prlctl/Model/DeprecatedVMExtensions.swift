import Foundation

// This file just contains old, deprecated methods now
extension PackagedVM {
    @discardableResult
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func unpack() throws -> StoppedVM {
        try DefaultParallelsCommandRunner().unpackVM(handle: self.uuid)
        return StoppedVM(uuid: uuid, name: name)
    }
}

extension RunningVM {
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func shutdown(immediately: Bool = false) throws {
        try DefaultParallelsCommandRunner().stopVM(handle: uuid, fast: immediately)
    }

    @discardableResult
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func runCommand(_ command: String, as user: User = .root) throws -> String {
        var internalCommand = command

        if user != .root {
            internalCommand = "su - '\(user.name)' -c '\(command)'"
        }

        return  try DefaultParallelsCommandRunner().runCommandOnVM(handle: self.uuid, command: internalCommand)
    }
}

extension StoppedVM {
    /// Start the VM
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func start(wait: Bool = true) throws {
        try DefaultParallelsCommandRunner().startVM(handle: self.uuid, wait: wait)
    }

    /// Clone the VM
    ///
    /// - Parameters:
    ///     - as: The name to use for the new VM
    ///     - fast: Whether to use the Parallels linked clone feature to speed up VM cloning (on by default)
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func clone(as newName: String, fast: Bool = true) throws {
        try DefaultParallelsCommandRunner().cloneVM(handle: self.uuid, newName: newName, fast: fast)
    }

    /// Clean up the VM by removing all snapshots.
    ///
    /// Snapshots are created by running `clone` in `fast` mode – they need to be cleaned because
    /// otherwise they can take up a lot of disk space.
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func clean() throws {
        try DefaultParallelsCommandRunner().deleteAllSnapshots(handle: self.uuid)
    }

    /// Retrieve a list of snapshots associated with this VM
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func getSnapshots() throws -> [VMSnapshot] {
        try DefaultParallelsCommandRunner().getSnapshots(handle: self.uuid)
    }

    /// Delete the given snapshot object from this VM
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func deleteSnapshot(_ snapshot: VMSnapshot) throws {
        try DefaultParallelsCommandRunner().deleteSnapshot(snapshot)
    }

    /// Rename the VM to the given `name`
    ///
    /// This will persistently change the name inside of the Parallels VM bundle
    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func rename(to name: String) throws {
        try DefaultParallelsCommandRunner().renameVM(handle: self.uuid, newName: name)
    }

    @available(*, deprecated, message: "Use the Parallels() actor instead")
    public func set(_ option: VMOption) throws {
        try DefaultParallelsCommandRunner().setVMOption(handle: self.uuid, option: option)
    }
}

extension VMProtocol {
    /// Delete this VM
    @available(*, deprecated, message: "Use `Parallels.deleteVM(withHandle:)` instead")
    public func delete() throws {
        // It's ok if trying to stop the VM fails – it might already be stopped
        try? DefaultParallelsCommandRunner().stopVM(handle: uuid, fast: true)
        try DefaultParallelsCommandRunner().deleteVM(handle: uuid)
    }

    /// Unregister this VM from Parallels without deleting any files on disk
    @available(*, deprecated, message: "Use `Parallels.unregisterVM(withHandle:)` instead")
    public func unregister() throws {
        try DefaultParallelsCommandRunner().unregisterVM(handle: uuid)
    }
}
