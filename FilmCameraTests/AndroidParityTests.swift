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
            XCTAssertLessThan(mean,2.5,config.name); XCTAssertLessThanOrEqual(maximum,16,config.name)
            report.append(["pass":config.name,"meanAbsoluteByteError":mean,"maximumByteError":maximum])
        }
        let data = try JSONSerialization.data(withJSONObject:report,options:.prettyPrinted)
        let attachment = XCTAttachment(data:data,uniformTypeIdentifier:"public.json"); attachment.name = "Android-iOS shader comparison"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
