import Foundation

public struct PackagedVM: VMProtocol {
    public let uuid: String
    public let name: String

    init(uuid: String, name: String) {
        self.uuid = uuid
        self.name = name
    }

    @discardableResult
    public func unpack(runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) throws -> StoppedVM {
        try runner.prlctl("unpack", uuid)
        return StoppedVM(uuid: uuid, name: name)
    }
}
