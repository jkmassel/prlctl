import Foundation

struct ParallelsService {

    private let runner: ParallelsCommandRunner

    public init() {
        self.init(runner: DefaultParallelsCommandRunner())
    }

    public init(runner: ParallelsCommandRunner) {
        self.runner = runner
    }

    func installLicense(key: String, company: String) throws {
        try runner.runCommand(components: ["prlsrvctl", "install-license", "-k", key, "--company", company, "--activate-online-immediately"])
    }
}
