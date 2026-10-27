import XCTest
@testable import FilmCamera

final class BMCRemoteAuthenticationTests: XCTestCase {
    func testSecureNonceHasRequiredLength() throws {
        let first = try BMCRemoteAuthentication.makeNonce()
        let second = try BMCRemoteAuthentication.makeNonce()
        XCTAssertEqual(first.count, 32)
        XCTAssertEqual(second.count, 32)
        XCTAssertNotEqual(first, second)
    }
    func testRecoveredChallengeDigest() throws {
        let nonce = Data((0..<64).map { UInt8($0) })
        XCTAssertEqual(try BMCRemoteAuthentication.response(password: "test", nonce: nonce), "6df18b13090db32b14b0e54842a4a2f1b7c94c2b411d86f250aa0b37443a61f1")
        XCTAssertEqual(try BMCRemoteAuthentication.response(password: "café", nonce: Data(repeating: 255, count: 64)), "a54d6ccb0378669acb59c58ac6f070cf3a9b7ad9bf67d1c063a010af803088a9")
        XCTAssertThrowsError(try BMCRemoteAuthentication.response(password: "test", nonce: Data(repeating: 0, count: 63)))
    }
    func testRecoveredHexDecoding() throws {
        XCTAssertEqual(try BMCRemoteAuthentication.decodeHex("abcD"), Data([0xab, 0xcd]))
        XCTAssertEqual(try BMCRemoteAuthentication.decodeHex("f"), Data([0x0f]))
        XCTAssertThrowsError(try BMCRemoteAuthentication.decodeHex("zz"))
    }
}

