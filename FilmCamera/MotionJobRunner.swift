import UIKit
import CoreImage

enum MotionJobRunner {
    static func run(_ job:MotionExportJob,progress:@escaping (Double)->Void) async throws {
        let clip = try MotionClip(url:job.source)
        guard job.first >= 0,job.first <= job.last,job.last < clip.count else {throw PortError.message("Invalid queued export frame range.")}
        let range = job.first...job.last
        if job.kind == "Movie" {
            let silent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".mov")
            let wav = job.destination.deletingPathExtension().appendingPathExtension("wav")
            defer {try? FileManager.default.removeItem(at:silent)}
            try await MotionVideoExport.encode(clip:clip,range:range,destination:silent,settings:job.settings,lut:job.lut,codec:job.codec,fps:job.fps,bitrate:job.bitrate,resolution:job.resolution ?? .p1080,sourceTiming:job.sourceTiming == true,progress:progress)
            if (job.sourceTiming == true || abs(job.fps-clip.fps) <= max(1e-6,clip.fps*1e-6)),try clip.extractAudio(range:range,to:wav) {try await MotionAudio.mux(video:silent,audio:wav,to:job.destination)}
            else {try FileManager.default.moveItem(at:silent,to:job.destination)}
            if job.sourceTiming == true {for (name,data) in try clip.captureSidecars(range:range) {let ext = name == "motion.gcsv" ? "gcsv" : "capture-timing.json"; try data.write(to:job.destination.deletingPathExtension().appendingPathExtension(ext),options:.atomic)}}
        } else if job.kind == "JPEG" {
            let renderer = FilmRenderer(),decoded = try clip.image(job.first,context:renderer.context,maxDimension:4096)
            let source = MotionProcessing.photoInput(decoded,grade:job.settings.motion)
            let output = try renderer.render(source,settings:job.settings,lut:job.lut)
            guard let cg = renderer.context.createCGImage(output,from:output.extent),let data = UIImage(cgImage:cg).jpegData(compressionQuality:0.95) else {throw PortError.message("JPEG encoding failed.")}
            try Task.checkCancellation(); try data.write(to:job.destination,options:.atomic)
        } else if job.kind == "DNG" {try Task.checkCancellation(); try clip.dng(job.first).write(to:job.destination,options:.atomic)}
        else if job.kind == "CinemaDNG ZIP" {
            let archive = try MotionArchive(url:job.destination)
            var success = false
            defer {if !success {try? FileManager.default.removeItem(at:job.destination)}}
            for frame in range {
                try Task.checkCancellation()
                try archive.append(name:String(format:"%06d.dng",frame-job.first),data:clip.dng(frame))
                progress(Double(frame-job.first+1)/Double(range.count))
            }
            if clip.isSequence {
                let wav = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".wav")
                defer {try? FileManager.default.removeItem(at:wav)}
                if try clip.extractAudio(range:range,to:wav) {try archive.append(name:"audio.wav",data:Data(contentsOf:wav,options:.mappedIfSafe))}
            }
            for (name,data) in try clip.captureSidecars(range:range) {try archive.append(name:name,data:data)}
            try archive.finish(); success = true
        } else {
            try FileManager.default.createDirectory(at:job.destination,withIntermediateDirectories:true)
            var success = false
            defer {if !success {try? FileManager.default.removeItem(at:job.destination)}}
            for frame in range {
                try Task.checkCancellation()
                let target = job.destination.appendingPathComponent(String(format:"%06d.dng",frame-job.first))
                try clip.dng(frame).write(to:target,options:.atomic)
                progress(Double(frame-job.first+1)/Double(range.count))
            }
            if clip.isSequence {_ = try clip.extractAudio(range:range,to:job.destination.appendingPathComponent("audio.wav"))}
            for (name,data) in try clip.captureSidecars(range:range) {try data.write(to:job.destination.appendingPathComponent(name),options:.atomic)}
            success = true
        }
    }
}
