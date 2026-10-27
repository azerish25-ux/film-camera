import Foundation
import XCTest
@testable import FilmCamera

final class BMCWebSocketLoopbackTests: XCTestCase {
    func testTextAndBinaryFramesAgainstLocalServer() async throws {
        let channel = try BMCWebSocketChannel(url: XCTUnwrap(URL(string: "ws://127.0.0.1:18765")))
        let frames = try await withThrowingTaskGroup(of: [BMCWebSocketFrame].self) { group in
            group.addTask {
                try await channel.send(text: "hello")
                let first = try await channel.receiveFrame()
                try await channel.send(binary: Data([1, 2, 3]))
                let second = try await channel.receiveFrame()
                return [first, second]
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 15_000_000_000)
                throw NSError(domain: "LoopbackTimeout", code: 1)
            }
            do {
                let value = try await group.next() ?? []
                group.cancelAll()
                await channel.close()
                return value
            } catch {
                group.cancelAll()
                await channel.close()
                throw error
            }
        }
        XCTAssertEqual(frames, [.text("world"), .binary(Data([4, 5, 6]))])
    }
}
