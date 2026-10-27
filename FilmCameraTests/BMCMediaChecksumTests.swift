import Foundation
import XCTest
@testable import FilmCamera

final class BMCMediaChecksumTests: XCTestCase {
    func testCRC32KnownVectorAndIncrementalUpdates() {
        var whole = BMCMediaChecksum()
        XCTAssertEqual(whole.value, 0)
        whole.update(Data("123456789".utf8))
        XCTAssertEqual(whole.value, 0xcbf43926)
        var split = BMCMediaChecksum()
        split.update(Data("1234".utf8))
        split.update(Data("56789".utf8))
        XCTAssertEqual(split.value, whole.value)
        split.update(Data("!".utf8))
        XCTAssertNotEqual(split.value, whole.value)
    }
}
