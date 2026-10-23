import XCTest
import AVFoundation
import CoreImage
import UIKit
@testable import FilmCamera

final class MediaExportTests: XCTestCase {
    @MainActor func testVideoExportRetainsAudioAndTrims() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:folder)}
        let source = try await Self.movie(in:folder)
        let exporter = MediaExporter(), output = folder.appendingPathComponent("graded.mov")
        var settings = FilmSettings(); settings["exposure"] = -0.5; settings["halation"] = 0.2
        try await exporter.exportVideo(source:source,destination:output,settings:settings,lut:nil,start:0.125,end:0.375,resolution:AVAssetExportPreset1280x720)
        let asset = AVURLAsset(url:output)
        let duration = try await asset.load(.duration).seconds
        XCTAssertEqual(duration,0.25,accuracy:0.05)
        let audio = try await asset.loadTracks(withMediaType:.audio), video = try await asset.loadTracks(withMediaType:.video)
        XCTAssertEqual(audio.count,1); XCTAssertEqual(video.count,1)
        let generator = AVAssetImageGenerator(asset:asset)
        XCTAssertNotNil(try generator.copyCGImage(at:CMTime(seconds:0.1,preferredTimescale:600),actualTime:nil))
        XCTAssertFalse(exporter.busy); XCTAssertEqual(exporter.progress,1)
    }
    @MainActor func testPhotoExportWritesReadablePixels() throws {
        let image = UIImage(ciImage:CIImage(color:CIColor(red:0.3,green:0.5,blue:0.7)).cropped(to:CGRect(x:0,y:0,width:128,height:96)))
        var settings = FilmSettings(); settings.look = OriginalFilm.all[1].name
        let result = try FilmRenderer().photo(image,settings:settings,lut:nil)
        XCTAssertEqual(result.size.width,128)
        let data = try XCTUnwrap(result.jpegData(compressionQuality:0.97))
        XCTAssertNotNil(UIImage(data:data)); XCTAssertGreaterThan(data.count,100)
    }
    static func movie(in folder: URL) async throws -> URL {
        let raw = folder.appendingPathComponent("video.mp4")
        let writer = try AVAssetWriter(outputURL:raw,fileType:.mp4)
        let input = AVAssetWriterInput(mediaType:.video,outputSettings:[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:128,AVVideoHeightKey:96])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:128,kCVPixelBufferHeightKey as String:96])
        writer.add(input); XCTAssertTrue(writer.startWriting()); writer.startSession(atSourceTime:.zero)
        for frame in 0..<12 {
            while !input.isReadyForMoreMediaData {try await Task.sleep(nanoseconds:1_000_000)}
            var pixel: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault,128,96,kCVPixelFormatType_32ARGB,nil,&pixel)
            let buffer = try XCTUnwrap(pixel); CVPixelBufferLockBaseAddress(buffer,[])
            let pointer = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to:UInt8.self), stride = CVPixelBufferGetBytesPerRow(buffer)
            for y in 0..<96 {for x in 0..<128 {let offset = y*stride+x*4; pointer[offset]=255;pointer[offset+1]=UInt8(x+frame);pointer[offset+2]=UInt8(y+60);pointer[offset+3]=180}}
            CVPixelBufferUnlockBaseAddress(buffer,[])
            XCTAssertTrue(adaptor.append(buffer,withPresentationTime:CMTime(value:Int64(frame),timescale:24)))
        }
        input.markAsFinished(); await writer.finishWriting(); XCTAssertEqual(writer.status,.completed)
        let wav = folder.appendingPathComponent("tone.wav")
        var wave = Data()
        func ascii(_ text: String) {wave.append(contentsOf:text.utf8)}
        func u16(_ value: UInt16) {var v=value.littleEndian;withUnsafeBytes(of:&v) {wave.append(contentsOf:$0)}}
        func u32(_ value: UInt32) {var v=value.littleEndian;withUnsafeBytes(of:&v) {wave.append(contentsOf:$0)}}
        let count=22050
        ascii("RIFF");u32(UInt32(36+count*2));ascii("WAVEfmt ");u32(16);u16(1);u16(1);u32(44100);u32(88200);u16(2);u16(16);ascii("data");u32(UInt32(count*2))
        for index in 0..<count {u16(UInt16(bitPattern:Int16(sin(Double(index)*2*Double.pi*440/44100)*8000)))}
        try wave.write(to:wav)
        let videoAsset=AVURLAsset(url:raw), audioAsset=AVURLAsset(url:wav), composition=AVMutableComposition()
        let videoTracks = try await videoAsset.loadTracks(withMediaType:.video)
        let audioTracks = try await audioAsset.loadTracks(withMediaType:.audio)
        let vt = try XCTUnwrap(videoTracks.first)
        let at = try XCTUnwrap(audioTracks.first)
        let range = CMTimeRange(start:.zero,duration:CMTime(value:12,timescale:24))
        try composition.addMutableTrack(withMediaType:.video,preferredTrackID:kCMPersistentTrackID_Invalid)?.insertTimeRange(range,of:vt,at:.zero)
        try composition.addMutableTrack(withMediaType:.audio,preferredTrackID:kCMPersistentTrackID_Invalid)?.insertTimeRange(range,of:at,at:.zero)
        let source=folder.appendingPathComponent("source.mov"), mux=try XCTUnwrap(AVAssetExportSession(asset:composition,presetName:AVAssetExportPresetPassthrough))
        mux.outputURL=source;mux.outputFileType = .mov;await mux.export()
        XCTAssertEqual(mux.status,.completed);return source
    }
}
