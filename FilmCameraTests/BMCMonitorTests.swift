import XCTest
import CoreImage
@testable import FilmCamera

final class BMCMonitorTests: XCTestCase {
    func testFalseColorThresholds() {
        XCTAssertEqual(BMCMonitor.falseColor(lightness: 0.97), .red)
        XCTAssertEqual(BMCMonitor.falseColor(lightness: 0.90), .yellow)
        XCTAssertEqual(BMCMonitor.falseColor(lightness: 0.64), .pink)
        XCTAssertEqual(BMCMonitor.falseColor(lightness: 0.47), .green)
        XCTAssertEqual(BMCMonitor.falseColor(lightness: 0.18), .blue)
        XCTAssertEqual(BMCMonitor.falseColor(lightness: 0.10), .purple)
        XCTAssertEqual(BMCMonitor.falseColor(lightness: 0.75), .gray)
        XCTAssertEqual(BMCMonitor.falseColor(lightness: 0.96820304), .yellow)
    }

    func testRec709LightnessAndZebraBoundaries() {
        XCTAssertEqual(BMCMonitor.rec709Lightness(red: 0, green: 0, blue: 0), 0, accuracy: 0.00001)
        XCTAssertEqual(BMCMonitor.rec709Lightness(red: 1, green: 1, blue: 1), 1, accuracy: 0.00001)
        XCTAssertTrue(BMCMonitor.zebraApplies(luminance: 0.95, threshold: 0.95, midGray: .off))
        XCTAssertFalse(BMCMonitor.zebraApplies(luminance: 0.4, threshold: 0.95, midGray: .off))
        XCTAssertTrue(BMCMonitor.zebraApplies(luminance: 0.39550781, threshold: 0.95, midGray: .middle))
        XCTAssertFalse(BMCMonitor.zebraApplies(luminance: 0.41894531, threshold: 0.95, midGray: .middle))
    }

    func testMonitorKernelRendersAndDisabledMonitoringIsIdentity() throws {
        let input = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: CGRect(x: 0, y: 0, width: 16, height: 16))
        XCTAssertTrue(try BMCMonitor.render(input, options: BMCMonitorOptions()) === input)
        var options = BMCMonitorOptions()
        options.falseColor = true
        let output = try BMCMonitor.render(input, options: options)
        var pixels = [UInt8](repeating: 0, count: 16 * 16 * 4)
        let context = CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull()])
        context.render(output, toBitmap: &pixels, rowBytes: 16 * 4, bounds: output.extent, format: .RGBA8, colorSpace: nil)
        XCTAssertGreaterThan(pixels[0], 200)
        XCTAssertLessThan(pixels[1], 30)
        XCTAssertLessThan(pixels[2], 20)
    }
}
