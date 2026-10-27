import XCTest
import CoreImage
@testable import FilmCamera

final class BMCTimelapseRoutingTests: XCTestCase {
    func testOnlyDueFramesAreRenderedAndAppended() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try MotionTimelapse(url: url, size: CGSize(width: 64, height: 64), interval: 1)
        let frame = CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5)).cropped(to: CGRect(x: 0, y: 0, width: 64, height: 64))
        XCTAssertTrue(writer.needsFrame(at: 0))
        for _ in 0..<100 { try writer.append(frame, time: 0); if writer.count == 1 { break }; Thread.sleep(forTimeInterval: 0.01) }
        XCTAssertEqual(writer.count, 1)
        XCTAssertFalse(writer.needsFrame(at: 0.5)); try writer.append(frame, time: 0.5)
        XCTAssertTrue(writer.needsFrame(at: 1))
        for _ in 0..<100 { try writer.append(frame, time: 1); if writer.count == 2 { break }; Thread.sleep(forTimeInterval: 0.01) }
        XCTAssertEqual(writer.count, 2)
        XCTAssertFalse(writer.needsFrame(at: .nan))
        let finished = expectation(description: "Timelapse finished")
        writer.finish { result in if case .failure(let error) = result { XCTFail(error.localizedDescription) }; finished.fulfill() }
        wait(for: [finished], timeout: 10)
    }
}
