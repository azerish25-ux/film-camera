import Foundation
import XCTest
@testable import FilmCamera

final class BMCMediaLoopbackTests: XCTestCase {
    func testAuthorizationAndMediaChunkFromLocalMock() async throws {
        let channel = try BMCWebSocketChannel(url: XCTUnwrap(URL(string: "ws://127.0.0.1:18766")))
        let session = BMCRemoteSignalingSession(channel: channel)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data()))
        defer { try? FileManager.default.removeItem(at: url) }
        let receiver = try BMCMediaReceiver(handle: FileHandle(forWritingTo: url), clipID: "A", offset: 0, totalSize: 4)
        let participant = BMCParticipant(uuid: "00000000-0000-0000-0000-000000000001", modelName: "phone", deviceName: "Camera", slateName: "A", major: 5, minor: 0)
        let output = try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                try await session.authorize(participant: participant, password: "test", nonce: Data(repeating: 1, count: 32))
                let transfer = BMCMediaTransfer(sender: session, receiver: receiver)
                try await transfer.requestRemaining()
                guard case .binary(let packet) = try await session.receiveFrame() else { throw NSError(domain: "ExpectedBinary", code: 1) }
                let remaining = try await transfer.accept(packet)
                guard remaining.isEmpty, await receiver.isComplete else { throw NSError(domain: "IncompleteTransfer", code: 1) }
                return try Data(contentsOf: url)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 25_000_000_000)
                throw NSError(domain: "LoopbackTimeout", code: 1)
            }
            do {
                let value = try await group.next() ?? Data()
                group.cancelAll()
                await session.close()
                return value
            } catch {
                group.cancelAll()
                await session.close()
                throw error
            }
        }
        try await receiver.close()
        XCTAssertEqual(output, Data("DATA".utf8))
    }
}
