import Foundation
import XCTest
@testable import prlctl

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

final class ParallelsTests: XCTestCase {

    func testThatLookupAllVMsIsEmptyForNoVMs() async throws {
        let parallels = Parallels(runner: TestCommandRunner(responses: [
            "prlctl list --json --full --all": "[]",
            "prlctl list --json --full --all --info": "[]"
        ]))

        let result = try await parallels.lookupAllVMs()
        XCTAssertTrue(result.isEmpty)
    }

    func testThatLookupAllVMsThrowsForInvalidJSON() async throws {
        let parallels = Parallels(runner: TestCommandRunner(responses: [
            "prlctl list --json --full --all": "foo",
            "prlctl list --json --full --all --info": "[]"
        ]))

        do {
            _ = try await parallels.lookupAllVMs()
            XCTFail("There should be an error looking up VMs")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testThatInvalidVMsCanBeLookedUp() async throws {
        let parallels = try getParallelsWithTestData()
        let result = try await parallels.lookupInvalidVMs()
        XCTAssertEqual(1, result.count)
    }

    func testThatPackagedVMsCanBeLookedUp() async throws {
        let parallels = try getParallelsWithTestData()
        let result = try await parallels.lookupPackagedVMs()
        XCTAssertEqual(1, result.count)
    }

    func testThatResumingVMsCanBeLookedUp() async throws {
        let parallels = try getParallelsWithTestData()
        let result = try await parallels.lookupResumingVMs()
        XCTAssertEqual(1, result.count)
    }

    func testThatRunningVMsCanBeLookedUp() async throws {
        let parallels = try getParallelsWithTestData()
        let result = try await parallels.lookupRunningVMs()
        XCTAssertEqual(3, result.count)
    }

    func testThatStoppedVMsCanBeLookedUp() async throws {
        let parallels = try getParallelsWithTestData()
        let result = try await parallels.lookupStoppedVMs()
        XCTAssertEqual(1, result.count)
    }

    func testThatSuspendedVMsCanBeLookedUp() async throws {
        let parallels = try getParallelsWithTestData()
        let result = try await parallels.lookupSuspendedVMs()
        XCTAssertEqual(1, result.count)
    }

    func testThatLookupVMReturnsNilForInvalidHandle() async throws {
        let parallels = try getParallelsWithTestData()
        let vm = try await parallels.lookupVM(named: "invalid-vm-handle")
        XCTAssertNil(vm)
    }

    func testThatLookupVMReturnsPackagedVM() async throws {
        let parallels = try getParallelsWithTestData()
        let vm = try await parallels.lookupVM(named: "packaged-vm")
        XCTAssertNotNil(vm?.asPackagedVM())
    }

    func testThatLookupVMReturnsResumingVM() async throws {
        let parallels = try getParallelsWithTestData()
        let vm = try await parallels.lookupVM(named: "resuming-vm")
        XCTAssertNotNil(vm?.asResumingVM())
    }

    func testThatLookupVMReturnsRunningVM() async throws {
        let parallels = try getParallelsWithTestData()
        let vm = try await parallels.lookupVM(named: "running-vm-with-ip")
        XCTAssertNotNil(vm?.asRunningVM())
    }

    func testThatLookupVMReturnsRunningIPV6VM() async throws {
        let parallels = try getParallelsWithTestData()
        let vm = try await parallels.lookupVM(named: "running-vm-with-ipv6")
        XCTAssertNotNil(vm?.asRunningVM())
    }

    func testThatLookupVMReturnsStoppedVM() async throws {
        let parallels = try getParallelsWithTestData()
        let vm = try await parallels.lookupVM(named: "stopped-vm")
        XCTAssertNotNil(vm?.asStoppedVM())
    }

    func testThatLookupVMReturnsSuspendedVM() async throws {
        let parallels = try getParallelsWithTestData()
        let vm = try await parallels.lookupVM(named: "suspended-vm")
        XCTAssertNotNil(vm?.asSuspendedVM())
    }

    func testThatLicenseActivationWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).serviceControl.installLicense(key: "key", company: "company")
        XCTAssertEqual(
            runner.command,
            "prlsrvctl install-license -k key --company company --activate-online-immediately"
        )
    }

    func testThatRegisterVMWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).registerVM(at: URL(fileURLWithPath: "/dev/null"))
        XCTAssertEqual(runner.command, "prlctl register /dev/null --preserve-uuid=no")
    }

    func testThatUnregisterVMWorks() async throws {
        let runner = TestCommandRunner()
        try await Parallels(runner: runner).unregisterVM(named: "foo")
        XCTAssertEqual(runner.command, "prlctl unregister foo")
    }

    private func getParallelsWithTestData() throws -> Parallels {
        return Parallels(runner: TestCommandRunner(responses: [
            "prlctl list --json --full --all": try getVMList(),
            "prlctl list --json --full --all --info": try getVMDetails()
        ]))
    }

    private let testVMNames = [
        "invalid-vm",
        "packaged-vm",
        "running-vm-with-ip",
        "running-vm-with-ipv6",
        "running-vm-without-ip",
        "stopped-vm",
        "suspended-vm",
        "resuming-vm"
    ]

    private func getVMList() throws -> String {
        let vms = try testVMNames
            .compactMap { getJSONResource(named: $0).data(using: .utf8) }
            .map { try JSONDecoder().decode(CodableVM.self, from: $0) }

        let data = try JSONEncoder().encode(vms)
        return String(data: data, encoding: .utf8)!
    }

    private func getVMDetails() throws -> String {
        let vms = try testVMNames
            .map { $0.appending("-details") }
            .compactMap { getJSONResource(named: $0).data(using: .utf8) }
            .map { try JSONDecoder().decode(VMDetails.self, from: $0) }

        let data = try JSONEncoder().encode(vms)
        return String(data: data, encoding: .utf8)!
    }
}

extension XCTestCase {

    struct VMTestData {
        let info: Data
        let details: Data

        func parse() throws -> VM? {
            let info = try JSONDecoder().decode(CodableVM.self, from: self.info)
            let details = try JSONDecoder().decode(VMDetails.self, from: self.details)

            return VM(vm: info, details: details)
        }
    }

    func codableVMResource(named name: String) throws -> CodableVM? {
        try JSONDecoder().decode(CodableVM.self, from: getJSONDataForResource(named: name))
    }

    func codableVMListResource(named name: String) throws -> CodableVMSnapshotList? {
        try JSONDecoder().decode(CodableVMSnapshotList.self, from: getJSONDataForResource(named: name))
    }

    func vmDetailsResource(named name: String) throws -> VMDetails? {
        try JSONDecoder().decode(VMDetails.self, from: getJSONDataForResource(named: name))
    }

    func getVmDataFrom(infoKey: String, detailsKey: String) -> VMTestData {
        let infoData = getJSONDataForResource(named: infoKey)
        let detailsData = getJSONDataForResource(named: detailsKey)

        return VMTestData(info: infoData, details: detailsData)
    }

    func getJSONDataForResource(named key: String) -> Data {
        let path = Bundle.module.path(forResource: key, ofType: "json")!
        return FileManager.default.contents(atPath: path)!
    }

    func getJSONResource(named key: String) -> String {
        let data = getJSONDataForResource(named: key)
        return String(data: data, encoding: .utf8)!
    }
}

extension RunningVM {
    static var testCase: RunningVM {
        RunningVM(uuid: "machine-uuid", name: "machine-name", ipAddress: "127.0.0.1")
    }
}
