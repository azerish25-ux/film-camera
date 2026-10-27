import XCTest
import CoreImage
@testable import FilmCamera

/// Run only with fixtures produced by BMCReferenceMain on Android GLES.
final class BMCReferenceTests: XCTestCase {
    func testFalseColorAgainstAndroid() throws {
        var options = BMCMonitorOptions(); options.falseColor = true
        try compare("false-color") { try BMCMonitor.render($0, options: options) }
    }
    func testZebraAgainstAndroid() throws {
        var options = BMCMonitorOptions(); options.zebra = true; options.zebraThreshold = 0.75
        try compare("zebra") { try BMCMonitor.render($0, options: options, zebraShift: 0) }
    }
    func testFocusAgainstAndroid() throws {
        var options = BMCFocusOptions(); options.enabled = true; options.value = 75; options.color = .red
        try compare("focus") { try BMCFocus.render($0, source: $0, options: options) }
    }
    private func compare(_ name: String, render: (CIImage) throws -> CIImage) throws {
        let bundle = Bundle(for: BMCReferenceTests.self)
        func fixture(_ suffix: String) throws -> Data {
            let url = try XCTUnwrap(bundle.url(forResource: "\(name)-\(suffix)", withExtension: "rgba"))
            return try Data(contentsOf: url)
        }
        let input = try fixture("input"), expected = [UInt8](try fixture("android"))
        XCTAssertEqual(input.count, 128 * 96 * 4); XCTAssertEqual(expected.count, 128 * 96 * 4)
        let image = CIImage(bitmapData: input, bytesPerRow: 128 * 4, size: CGSize(width: 128, height: 96), format: .RGBA8, colorSpace: nil)
        let output = try render(image)
        let context = CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull()])
        var bytes = [UInt8](repeating: 0, count: expected.count)
        bytes.withUnsafeMutableBytes { context.render(output, toBitmap: $0.baseAddress!, rowBytes: 128 * 4, bounds: CGRect(x: 0, y: 0, width: 128, height: 96), format: .RGBA8, colorSpace: nil) }
        var mismatches = 0, maxDifference = 0
        // The APK clamps its camera texture at the edge. Restrict this first
        // comparison to the interior while border sampling is investigated.
        for y in 2..<94 { for x in 2..<126 { for channel in 0..<3 {
            let index = (y * 128 + x) * 4 + channel
            let difference = abs(Int(bytes[index]) - Int(expected[index]))
            maxDifference = max(maxDifference, difference)
            if difference > 2 { mismatches += 1 }
        } } }
        let attachment = XCTAttachment(data: Data(bytes), uniformTypeIdentifier: "public.data")
        attachment.name = "\(name)-ios.rgba"; attachment.lifetime = .keepAlways; add(attachment)
        XCTAssertEqual(mismatches, 0, "\(name): \(mismatches) channel values differ by more than 2/255; maximum difference \(maxDifference)")
    }
}
