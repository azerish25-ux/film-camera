import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Text frames for the APK's app-camera WebSocket signaling handshake.
protocol BMCSignalingChannel: Sendable {
    func send(text: String) async throws
    func send(binary: Data) async throws
    func receiveText() async throws -> String
    func receiveFrame() async throws -> BMCWebSocketFrame
    func close() async
}

enum BMCWebSocketFrame: Equatable, Sendable {
    case text(String)
    case binary(Data)
}

/// URLSession provides WebSocket transport; this channel does not implement
/// WebRTC or a camera-control data channel.
actor BMCWebSocketChannel: BMCSignalingChannel {
    private let session: URLSession
    private let socket: URLSessionWebSocketTask

    init(url: URL) throws {
        guard let scheme = url.scheme?.lowercased(), ["ws", "wss"].contains(scheme), url.host != nil else {
            throw PortError.message("Invalid remote camera WebSocket address.")
        }
        let session = URLSession(configuration: .default)
        self.session = session
        socket = session.webSocketTask(with: url)
        socket.resume()
    }

    func send(text: String) async throws { try await socket.send(.string(text)) }
    func send(binary: Data) async throws { try await socket.send(.data(binary)) }
    func receiveFrame() async throws -> BMCWebSocketFrame {
        switch try await socket.receive() {
        case .string(let text): return .text(text)
        case .data(let data): return .binary(data)
        @unknown default: throw PortError.message("Unknown remote signaling message.")
        }
    }
    func receiveText() async throws -> String {
        switch try await receiveFrame() {
        case .text(let text): return text
        case .binary: throw PortError.message("Unexpected binary signaling message during pairing.")
        }
    }
    func close() async {
        socket.cancel(with: .goingAway, reason: nil)
        session.invalidateAndCancel()
    }
}

/// Runs only the recovered client-side authorization exchange. On failure or
/// timeout the channel is closed; on success it remains open for the caller.
enum BMCSignalingAuthenticator {
    static func authenticate(channel: any BMCSignalingChannel, participant: BMCParticipant, password: String, nonce: Data, timeoutNanoseconds: UInt64 = 15_000_000_000) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                var handshake = BMCClientHandshake()
                func send(_ message: BMCSignalingMessage) async throws {
                    let data = try JSONEncoder().encode(message)
                    guard let text = String(data: data, encoding: .utf8) else { throw PortError.message("Cannot encode remote signaling message.") }
                    try await channel.send(text: text)
                }
                try await send(handshake.begin(info: participant, nonce: nonce))
                for _ in 0..<2 {
                    let text = try await channel.receiveText()
                    let incoming = try JSONDecoder().decode(BMCSignalingMessage.self, from: Data(text.utf8))
                    let reply = try handshake.receive(incoming, password: password)
                    if let reply { try await send(reply) }
                    else if !handshake.authorized { throw PortError.message("Remote pairing ended before authorization.") }
                }
                guard handshake.authorized else { throw PortError.message("Remote pairing was not authorized.") }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
                throw PortError.message("Remote camera pairing timed out.")
            }
            do {
                _ = try await group.next()
                group.cancelAll()
            } catch {
                group.cancelAll()
                await channel.close()
                throw error
            }
        }
    }
}

/// Owns authorization state for post-pairing signaling and media-sync frames.
/// Camera control still requires its separate WebRTC data channel.
actor BMCRemoteSignalingSession {
    private enum State { case idle, authorizing, authorized, closed }
    private let channel: any BMCSignalingChannel
    private var state: State = .idle
    private var sending = false
    private var receiving = false

    init(channel: any BMCSignalingChannel) { self.channel = channel }

    func authorize(participant: BMCParticipant, password: String, nonce: Data, timeoutNanoseconds: UInt64 = 15_000_000_000) async throws {
        guard state == .idle else { throw PortError.message("Remote session is not ready to pair.") }
        state = .authorizing
        do {
            try await BMCSignalingAuthenticator.authenticate(channel: channel, participant: participant, password: password, nonce: nonce, timeoutNanoseconds: timeoutNanoseconds)
            guard state == .authorizing else { throw PortError.message("Remote session was closed during pairing.") }
            state = .authorized
        } catch {
            state = .closed
            await channel.close()
            throw error
        }
    }

    func sendBinary(_ data: Data) async throws {
        guard state == .authorized, !sending else { throw PortError.message("Remote session cannot send media data.") }
        sending = true
        defer { sending = false }
        try await channel.send(binary: data)
    }

    func receiveFrame() async throws -> BMCWebSocketFrame {
        guard state == .authorized, !receiving else { throw PortError.message("Remote session cannot receive data.") }
        receiving = true
        defer { receiving = false }
        return try await channel.receiveFrame()
    }

    func close() async {
        state = .closed
        await channel.close()
    }
}

