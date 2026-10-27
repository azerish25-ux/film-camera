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
    func testLuminanceDiagnostics() throws {
        let bundle = Bundle(for: BMCReferenceTests.self)
        let inputURL = try XCTUnwrap(bundle.url(forResource: "luminance-f32-input", withExtension: "rgba"))
        let expectedURL = try XCTUnwrap(bundle.url(forResource: "luminance-f32-android", withExtension: "rgba"))
        let input = try Data(contentsOf: inputURL), expected = [UInt8](try Data(contentsOf: expectedURL))
        XCTAssertEqual(input.count, 128 * 96 * 4); XCTAssertEqual(expected.count, 128 * 96 * 4)
        let image = CIImage(bitmapData: input, bytesPerRow: 128 * 4, size: CGSize(width: 128, height: 96), format: .RGBA8, colorSpace: nil)
        let luminance = try BMCMonitor.luminanceImage(image)
        let context = CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull()])
        var values = [Float](repeating: 0, count: 128 * 96 * 4)
        values.withUnsafeMutableBytes { context.render(luminance, toBitmap: $0.baseAddress!, rowBytes: 128 * 16, bounds: CGRect(x: 0, y: 0, width: 128, height: 96), format: .RGBAf, colorSpace: nil) }
        var maximum: Float = 0
        for y in 2..<94 { for x in 2..<126 {
            let index = (y * 128 + x) * 4
            let bits = UInt32(expected[index]) | (UInt32(expected[index + 1]) << 8) | (UInt32(expected[index + 2]) << 16) | (UInt32(expected[index + 3]) << 24)
            let android = Float(bitPattern: bits), ios = values[index]
            XCTAssertTrue(android.isFinite && ios.isFinite)
            maximum = max(maximum, abs(android - ios))
        } }
        let attachment = values.withUnsafeBytes { XCTAttachment(data: Data($0), uniformTypeIdentifier: "public.data") }
        attachment.name = "luminance-ios-rgbaf"; attachment.lifetime = .keepAlways; add(attachment)
        print("Maximum interior Android/iOS luminance difference: \(maximum)")
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
