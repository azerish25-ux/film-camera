import Foundation

/// Client-side signaling state only. A transport and a timeout owner are still
/// required before it can connect to a camera.
struct BMCClientHandshake {
    private enum State { case idle, helloSent, connectionSent, authorized, stopped }
    private var state: State = .idle
    var authorized: Bool { state == .authorized }

    mutating func begin(info: BMCParticipant, nonce: Data) throws -> BMCSignalingMessage {
        guard state == .idle, nonce.count == 32 else { throw PortError.message("Invalid remote pairing state or nonce.") }
        let hex = nonce.map { String(format: "%02x", $0) }.joined()
        state = .helloSent
        return .helloRequest(BMCHello(nonce: hex, info: info, controllerInfo: nil, status: nil))
    }

    mutating func receive(_ message: BMCSignalingMessage, password: String) throws -> BMCSignalingMessage? {
        switch (state, message) {
        case (.helloSent, .helloResponse(let hello)):
            guard hello.status != "busy" else { state = .stopped; throw PortError.message("Remote camera is busy.") }
            let nonce = try BMCRemoteAuthentication.decodeHex(hello.nonce)
            let response = try BMCRemoteAuthentication.response(password: password, nonce: nonce)
            state = .connectionSent
            return .connectionRequest(response)
        case (.connectionSent, .connectionResponse(let status)):
            guard status == "authorized" else { state = .stopped; throw PortError.message("Remote camera rejected pairing.") }
            state = .authorized
            return nil
        case (_, .bye):
            state = .stopped
            return nil
        default:
            throw PortError.message("Unexpected remote pairing message.")
        }
    }
}

