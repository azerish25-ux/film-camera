import Foundation
import Network

struct BMCResolvedService: Sendable {
    let host: String
    let port: Int

    var webSocketURL: URL? {
        var components = URLComponents()
        components.scheme = "ws"
        components.host = host
        components.port = port
        return components.url
    }
}

/// Resolves a discovered service without making a preliminary TCP connection.
/// One resolution can be active per instance.
@MainActor final class BMCServiceResolver: NSObject, NetServiceDelegate {
    private var service: NetService?
    private var continuation: CheckedContinuation<BMCResolvedService, Error>?

    func resolve(_ endpoint: NWEndpoint, timeout: TimeInterval = 10) async throws -> BMCResolvedService {
        try Task.checkCancellation()
        guard timeout.isFinite, timeout > 0,
              case let .service(name, type, domain, _) = endpoint else {
            throw PortError.message("Invalid remote camera service.")
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { pending in
                guard continuation == nil else {
                    pending.resume(throwing: PortError.message("A service resolution is already in progress."))
                    return
                }
                let service = NetService(domain: domain, type: type, name: name)
                self.service = service
                continuation = pending
                service.delegate = self
                service.resolve(withTimeout: timeout)
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancel() }
        }
    }

    func cancel() { finish(.failure(CancellationError())) }

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard sender === service else { return }
        guard let host = sender.hostName, !host.isEmpty, (1...65_535).contains(sender.port) else {
            finish(.failure(PortError.message("Remote camera address is unavailable.")))
            return
        }
        finish(.success(BMCResolvedService(host: host, port: sender.port)))
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        guard sender === service else { return }
        finish(.failure(PortError.message("Remote camera service could not be resolved.")))
    }

    private func finish(_ result: Result<BMCResolvedService, Error>) {
        let pending = continuation
        continuation = nil
        let current = service
        service = nil
        current?.delegate = nil
        current?.stop()
        pending?.resume(with: result)
    }
}

