import XCTest
@testable import FilmCamera
final class AndroidParityTests: XCTestCase {
    func testRecoveredPassesAgainstAndroidEmulator() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource:"reference-cases",withExtension:"json"))
        let cases = try JSONDecoder().decode([ReferenceCase].self,from:Data(contentsOf:url))
        let pipeline = try OriginalFilmPipeline()
        var report: [[String:Any]] = []
        for config in cases {
            let expectedURL = try XCTUnwrap(Bundle.main.url(forResource:config.name,withExtension:"rgba"))
            let expected = Array(try Data(contentsOf:expectedURL)), actual = Array(try pipeline.probe(config))
            XCTAssertEqual(actual.count,expected.count)
            let pixels = XCTAttachment(data:Data(actual),uniformTypeIdentifier:"public.data"); pixels.name=config.name+".rgba"; pixels.lifetime = .keepAlways; add(pixels)
            let differences = zip(expected,actual).enumerated().filter {$0.offset%4 != 3}.map {abs(Int($0.element.0)-Int($0.element.1))}
            let mean = Double(differences.reduce(0,+))/Double(differences.count), maximum = differences.max() ?? 0
            // The Arri fixture's RGB gradient contains exact g == 1.3*r keys.
            // Normalizing UNORM8 and multiplying 1.3 can round to opposite sides
            // on Vulkan and Metal. Preserve the original strict keying formula;
            // compare every non-boundary pixel tightly and retain all-pixel metrics.
            func isExactKeyBoundary(_ pixel: Int) -> Bool {
                guard config.name == "gate-arri-frame", config.samplers["frameSuper16mm"] == "source" else {return false}
                let x = pixel%128, y = pixel/128
                let red = 1+x*253/127, green = 1+(95-y)*253/95
                return green*10 == red*13
            }
            var stableMaximum = 0, boundaryPixels = 0, divergentBoundaryPixels = 0
            for pixel in 0..<(128*96) {
                let delta = (0..<3).map {abs(Int(expected[pixel*4+$0])-Int(actual[pixel*4+$0]))}.max() ?? 0
                if isExactKeyBoundary(pixel) {boundaryPixels += 1; if delta > 2 {divergentBoundaryPixels += 1}}
                else {stableMaximum = max(stableMaximum,delta)}
            }
            XCTAssertLessThan(mean,0.25,config.name); XCTAssertLessThanOrEqual(stableMaximum,2,config.name)
            report.append(["pass":config.name,"meanAbsoluteByteError":mean,"maximumByteErrorOutsideExactKeyTies":stableMaximum,"maximumAllPixelByteError":maximum,"exactKeyBoundaryPixels":boundaryPixels,"differentKeyBoundaryPixels":divergentBoundaryPixels])
        }
        let data = try JSONSerialization.data(withJSONObject:report,options:.prettyPrinted)
        let attachment = XCTAttachment(data:data,uniformTypeIdentifier:"public.json"); attachment.name = "Android-iOS shader comparison"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
