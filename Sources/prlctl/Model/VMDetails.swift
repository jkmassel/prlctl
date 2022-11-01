import Foundation

public struct VMDetails: Codable {
    let uuid: String
    let name: String
    let description: String
    let state: VMStatus
    private let path: String
    private let optimization: VMOptimizationDetails

    public var isPackage: Bool {
        path.hasSuffix(".pvmp")
    }

    enum CodingKeys: String, CodingKey {
        case uuid = "ID"
        case name = "Name"
        case description = "Description"
        case state = "State"
        case path = "Home"
        case optimization = "Optimization"
    }
}

private struct VMOptimizationDetails: Codable {
    private let fasterVirtualMachine: String
    let hypervisorType: String

    enum CodingKeys: String, CodingKey {
        case fasterVirtualMachine = "Faster virtual machine"
        case hypervisorType = "Hypervisor type"
    }
}
