import Combine
import Foundation
import Network

struct BMCDiscoveredCamera: Identifiable {
    let record: BMCDiscoveryRecord
    let endpoint: NWEndpoint
    let serviceType: String
    var id: UUID { record.uuid }
}

/// Browses the two service types advertised by the APK. Resolving and pairing
/// a result is separate; simulator discovery does not validate iOS privacy.
@MainActor final class BMCDiscoveryBrowser: ObservableObject {
    static let serviceTypes = ["_bmd-cam-control._tcp", "_bmd-cam-control-android._tcp"]
    private static let txtKeys = ["name", "slate_name", "model_name", "proto", "ctrl_uuid", "ctrl_name", "ctrl_slate_name", "ctrl_model_name", "ctrl_proto"]

    @Published private(set) var cameras: [BMCDiscoveredCamera] = []
    @Published private(set) var statusMessage: String?
    private let queue = DispatchQueue(label: "BMCDiscoveryBrowser")
    private var browsers: [String: NWBrowser] = [:]
    private var resultsByType: [String: [UUID: BMCDiscoveredCamera]] = [:]
    private var errors: [String: String] = [:]
    private var generation = UUID()

    func start() {
        guard browsers.isEmpty else { return }
        generation = UUID()
        let token = generation
        for type in Self.serviceTypes {
            let browser = NWBrowser(for: .bonjourWithTXTRecord(type: type, domain: nil), using: .tcp)
            browser.browseResultsChangedHandler = { [weak self] results, _ in
                Task { @MainActor [weak self] in self?.apply(results, type: type, token: token) }
            }
            browser.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in self?.update(state, type: type, token: token) }
            }
            browsers[type] = browser
            browser.start(queue: queue)
        }
    }

    func stop() {
        generation = UUID()
        for browser in browsers.values { browser.cancel() }
        browsers.removeAll(); resultsByType.removeAll(); errors.removeAll()
        cameras = []; statusMessage = nil
    }

    private func apply(_ results: Set<NWBrowser.Result>, type: String, token: UUID) {
        guard token == generation else { return }
        var records: [UUID: BMCDiscoveredCamera] = [:]
        for result in results {
            guard case let .service(name, _, _, _) = result.endpoint,
                  case let .bonjour(txt) = result.metadata else { continue }
            let values = Dictionary(uniqueKeysWithValues: Self.txtKeys.compactMap { key in txt[key].map { (key, Data($0.utf8)) } })
            guard let record = BMCDiscoveryRecord(serviceName: name, attributes: values) else { continue }
            records[record.uuid] = BMCDiscoveredCamera(record: record, endpoint: result.endpoint, serviceType: type)
        }
        resultsByType[type] = records
        var combined: [UUID: BMCDiscoveredCamera] = [:]
        for serviceType in Self.serviceTypes {
            for (id, camera) in resultsByType[serviceType] ?? [:] where combined[id] == nil { combined[id] = camera }
        }
        cameras = combined.values.sorted {
            let order = $0.record.name.localizedCaseInsensitiveCompare($1.record.name)
            return order == .orderedSame ? $0.id.uuidString < $1.id.uuidString : order == .orderedAscending
        }
    }

    private func update(_ state: NWBrowser.State, type: String, token: UUID) {
        guard token == generation else { return }
        switch state {
        case .failed(let error), .waiting(let error): errors[type] = error.localizedDescription
        case .ready: errors.removeValue(forKey: type)
        default: break
        }
        statusMessage = errors.isEmpty ? nil : errors.keys.sorted().compactMap { errors[$0] }.joined(separator: "; ")
    }
}

