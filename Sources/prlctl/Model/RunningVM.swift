import Foundation
import Network

public struct RunningVM: VMProtocol {

    public let uuid: String
    public let name: String
    public let ipAddress: String

    init(uuid: String, name: String, ipAddress: String) {
        self.uuid = uuid
        self.name = name
        self.ipAddress = ipAddress
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

    public func shutdown(
        immediately: Bool = false,
        runner: ParallelsCommandRunner = .default
    ) throws {
        try runner.stopVM(handle: uuid, fast: immediately)
    }

    @discardableResult
    public func runCommand(
        _ command: String,
        as user: User = .root,
        runner: ParallelsCommandRunner = .default
    ) throws -> String {
        var internalCommand = command

        if user != .root {
            internalCommand = "su - '\(user.name)' -c '\(command)'"
        }

        return try runner.prlctl("exec", self.uuid, internalCommand)
    }
}
