import Foundation
import XCTest
@testable import BMCProtocolCheck

final class BMCMediaReceiverTests: XCTestCase {
    func testValidatesChunkBeforeWritingAndSupportsResume() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: Data("12".utf8)))
        defer { try? FileManager.default.removeItem(at: url) }
        let handle = try FileHandle(forWritingTo: url)
        XCTAssertThrowsError(try BMCMediaReceiver(handle: handle, clipID: "A", offset: 3, totalSize: 9))
        let receiver = try BMCMediaReceiver(handle: handle, clipID: "A", offset: 2, totalSize: 9)
        var chunk = CamAppMediaSyncClipDataResponse()
        chunk.clipID = "A"; chunk.offset = 2; chunk.data = Data("3456789".utf8)
        var crc = BMCMediaChecksum(); crc.update(chunk.data); chunk.dataCrc32 = crc.value
        var invalid = chunk; invalid.dataCrc32 ^= 1
        do { try await receiver.accept(invalid); XCTFail("Expected checksum failure") } catch { }
        XCTAssertEqual(try Data(contentsOf: url), Data("12".utf8))
        invalid = chunk; invalid.offset = 3
        do { try await receiver.accept(invalid); XCTFail("Expected offset failure") } catch { }
        invalid = chunk; invalid.clipID = "B"
        do { try await receiver.accept(invalid); XCTFail("Expected clip ID failure") } catch { }
        invalid = chunk; invalid.data.append(0)
        do { try await receiver.accept(invalid); XCTFail("Expected size failure") } catch { }
        XCTAssertEqual(try Data(contentsOf: url), Data("12".utf8))
        try await receiver.accept(chunk)
        let complete = await receiver.isComplete
        XCTAssertTrue(complete)
        XCTAssertEqual(try Data(contentsOf: url), Data("123456789".utf8))
        try await receiver.close()
        do { try await receiver.accept(chunk); XCTFail("Expected a closed receiver to reject data") } catch { }
    }
}

