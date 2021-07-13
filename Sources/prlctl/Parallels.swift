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

    private func lookupVMs() throws -> [VM] {
        guard let output = try runner.runCommand(components: ["prlctl", "list", "--json", "--full", "--all"]).data(using: .utf8) else {
            return []
        }

        return try JSONDecoder().decode([VM].self, from: output)
    }

    public func lookupRunningVMs() throws -> [RunningVM] {
        try lookupVMs().compactMap { $0.asRunningVM }
    }

    public func lookupStoppedVMs() throws -> [StoppedVM] {
        try lookupVMs().compactMap { $0.asStoppedVM }
    }

    public func lookupVM(named handle: String) throws -> VMProtocol? {
        guard let vm = try lookupVMs().filter({ $0.uuid == handle || $0.name == handle }).first else {
            return nil
        }

        return vm.asRunningVM ?? vm.asStoppedVM
    }
}
