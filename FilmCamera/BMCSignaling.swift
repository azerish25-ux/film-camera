import Foundation

/// DNS-SD TXT data recovered from the legacy Android NSD resolve callback.
/// This only parses advertisements; it does not browse or connect to a peer.
struct BMCDiscoveryRecord: Equatable {
    let uuid: UUID
    let name: String
    let slateName: String
    let modelName: String
    let major: Int
    let minor: Int
    let controllerUUID: String?
    let controllerName: String?
    let controllerSlateName: String?
    let controllerModelName: String?
    let controllerMajor: Int?
    let controllerMinor: Int?

    init?(serviceName: String, attributes: [String: Data]) {
        func text(_ key: String) -> String? {
            attributes[key].map { String(decoding: $0, as: UTF8.self) }
        }
        func version(_ text: String?) -> (Int?, Int?) {
            guard let text else { return (nil, nil) }
            let parts = text.components(separatedBy: ".")
            return (parts.first.flatMap { Int32($0).map { Int($0) } }, parts.last.flatMap { Int32($0).map { Int($0) } })
        }
        guard let uuid = UUID(uuidString: serviceName), let name = text("name"),
              let slateName = text("slate_name"), let modelName = text("model_name") else { return nil }
        let cameraVersion = version(text("proto"))
        let controllerVersion = version(text("ctrl_proto"))
        self.uuid = uuid; self.name = name; self.slateName = slateName; self.modelName = modelName
        major = cameraVersion.0 ?? -1; minor = cameraVersion.1 ?? -1
        controllerUUID = text("ctrl_uuid"); controllerName = text("ctrl_name")
        controllerSlateName = text("ctrl_slate_name"); controllerModelName = text("ctrl_model_name")
        controllerMajor = controllerVersion.0; controllerMinor = controllerVersion.1
    }
}

struct BMCParticipant: Codable, Equatable {
    let uuid: String
    let modelName: String
    let deviceName: String
    let slateName: String
    let major: Int
    let minor: Int
    enum CodingKeys: String, CodingKey {
        case uuid, modelName = "model_name", deviceName = "device_name", slateName = "slate_name"
        case major = "proto_major", minor = "proto_minor"
    }
}
struct BMCHello: Codable, Equatable {
    let nonce: String
    let info: BMCParticipant
    let controllerInfo: BMCParticipant?
    let status: String?
    enum CodingKeys: String, CodingKey { case nonce, info, controllerInfo = "controller_info", status }
    // The APK's encoder emits info and nonce; its decoder also accepts the
    // optional controller_info and status fields.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nonce, forKey: .nonce)
        try container.encode(info, forKey: .info)
    }
}

enum BMCSignalingMessage: Codable, Equatable {
    case helloRequest(BMCHello), helloResponse(BMCHello)
    case connectionRequest(String), connectionResponse(String)
    case iceCandidate(String), sdpOffer(String), sdpAnswer(String), bye(String?)

    private enum Keys: String, CodingKey { case type, data }
    private enum PayloadKeys: String, CodingKey { case password, status, value, reason }
    private enum Kind: String, Codable {
        case helloRequest = "hello_request", helloResponse = "hello_response", connectionRequest = "conn_request"
        case connectionResponse = "conn_response", iceCandidate = "ice_candidate", sdpOffer = "sdp_offer"
        case sdpAnswer = "sdp_answer", bye = "bye_message"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(Kind.self, forKey: .type)
        switch type {
        case .helloRequest: self = .helloRequest(try container.decode(BMCHello.self, forKey: .data))
        case .helloResponse: self = .helloResponse(try container.decode(BMCHello.self, forKey: .data))
        default:
            let data = try container.nestedContainer(keyedBy: PayloadKeys.self, forKey: .data)
            switch type {
            case .connectionRequest: self = .connectionRequest(try data.decode(String.self, forKey: .password))
            case .connectionResponse: self = .connectionResponse(try data.decode(String.self, forKey: .status))
            case .iceCandidate: self = .iceCandidate(try data.decode(String.self, forKey: .value))
            case .sdpOffer: self = .sdpOffer(try data.decode(String.self, forKey: .value))
            case .sdpAnswer: self = .sdpAnswer(try data.decode(String.self, forKey: .value))
            case .bye: self = .bye(try data.decodeIfPresent(String.self, forKey: .reason))
            case .helloRequest, .helloResponse: throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid signaling type.")
            }
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        switch self {
        case .helloRequest(let hello): try container.encode(Kind.helloRequest, forKey: .type); try container.encode(hello, forKey: .data)
        case .helloResponse(let hello): try container.encode(Kind.helloResponse, forKey: .type); try container.encode(hello, forKey: .data)
        default:
            var data = container.nestedContainer(keyedBy: PayloadKeys.self, forKey: .data)
            switch self {
            case .connectionRequest(let value): try container.encode(Kind.connectionRequest, forKey: .type); try data.encode(value, forKey: .password)
            case .connectionResponse(let value): try container.encode(Kind.connectionResponse, forKey: .type); try data.encode(value, forKey: .status)
            case .iceCandidate(let value): try container.encode(Kind.iceCandidate, forKey: .type); try data.encode(value, forKey: .value)
            case .sdpOffer(let value): try container.encode(Kind.sdpOffer, forKey: .type); try data.encode(value, forKey: .value)
            case .sdpAnswer(let value): try container.encode(Kind.sdpAnswer, forKey: .type); try data.encode(value, forKey: .value)
            case .bye(let reason): try container.encode(Kind.bye, forKey: .type); try data.encodeIfPresent(reason, forKey: .reason)
            case .helloRequest, .helloResponse: break
            }
        }
    }
}
