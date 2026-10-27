import XCTest
import CoreImage
@testable import FilmCamera

final class BMCFocusTests: XCTestCase {
    func testColoredFocusLinesDetectAnEdgeButNotAFlatArea() throws {
        let bounds = CGRect(x: 0, y: 0, width: 32, height: 16)
        let black = CIImage(color: CIColor(red: 0, green: 0, blue: 0)).cropped(to: bounds)
        let white = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: CGRect(x: 16, y: 0, width: 16, height: 16))
        let source = white.composited(over: black).cropped(to: bounds)
        var options = BMCFocusOptions(); options.enabled = true; options.value = 75; options.color = .red
        let result = try BMCFocus.render(source, source: source, options: options)
        let context = CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull()])
        func pixel(_ x: Int) -> [UInt8] {
            var bytes = [UInt8](repeating: 0, count: 4)
            context.render(result, toBitmap: &bytes, rowBytes: 4, bounds: CGRect(x: x, y: 8, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
            return bytes
        }
        XCTAssertGreaterThan(pixel(15)[0], 240)
        XCTAssertLessThan(pixel(15)[1], 15)
        XCTAssertEqual(pixel(4)[0], 0)
    }
}
