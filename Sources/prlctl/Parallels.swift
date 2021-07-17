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
        guard let output = try runner.prlctl("list", "--json", "--full", "--all").data(using: .utf8) else {
            return []
        }

        // If for some reason we can't lookup VM Details, we can still continue
        let details = (try? lookupAllVMDetails(runner: runner)) ?? []

        return try JSONDecoder().decode([CodableVM].self, from: output).compactMap { vm in
            guard let vmDetails = details.first(where: { $0.uuid == vm.uuid }) else {
                return VM(vm: vm)
            }

            return VM(vm: vm, details: vmDetails)
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

    public func lookupVM(named handle: String) throws -> VM? {
        guard let vm = try lookupAllVMs().filter({ $0.uuid == handle || $0.name == handle }).first else {
            return nil
        }

        return vm
    }

    func lookupAllVMDetails(runner: ParallelsCommandRunner = DefaultParallelsCommandRunner()) throws -> [VMDetails] {
        guard let json = try runner.prlctl("list", "--json", "--full", "--all", "--info").data(using: .utf8) else {
            return []
        }

        return try JSONDecoder().decode([VMDetails].self, from: json)
    }

    func registerVM(at url: URL) throws {
        try runner.prlctl("register", url.path, "--preserve-uuid=no")
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
