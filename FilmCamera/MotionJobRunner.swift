import UIKit
import CoreImage

enum MotionJobRunner {
    static func run(_ job:MotionExportJob,progress:@escaping (Double)->Void) async throws {
        let clip = try MotionClip(url:job.source),range = job.first...job.last
        if job.kind == "Movie" {
            try await MotionVideoExport.encode(clip:clip,range:range,destination:job.destination,settings:job.settings,lut:job.lut,codec:job.codec,fps:job.fps,bitrate:job.bitrate,progress:progress)
        } else if job.kind == "JPEG" {
            let renderer = FilmRenderer(),source = try clip.image(job.first,context:renderer.context)
            let output = try renderer.render(source,settings:job.settings,lut:job.lut)
            guard let cg = renderer.context.createCGImage(output,from:output.extent),let data = UIImage(cgImage:cg).jpegData(compressionQuality:0.95) else {throw PortError.message("JPEG encoding failed.")}
            try Task.checkCancellation(); try data.write(to:job.destination,options:.atomic)
        } else if job.kind == "DNG" {try Task.checkCancellation(); try clip.dng(job.first).write(to:job.destination,options:.atomic)}
        else {
            try FileManager.default.createDirectory(at:job.destination,withIntermediateDirectories:true)
            var success = false
            defer {if !success {try? FileManager.default.removeItem(at:job.destination)}}
            for frame in range {
                try Task.checkCancellation()
                let target = job.destination.appendingPathComponent(String(format:"%06d.dng",frame-job.first))
                try clip.dng(frame).write(to:target,options:.atomic)
                progress(Double(frame-job.first+1)/Double(range.count))
            }
            success = true
        }
    }
}
