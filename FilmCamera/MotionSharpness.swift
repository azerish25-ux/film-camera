import UIKit

enum MotionSharpness {
    /// Native burst ranking by Laplacian energy.
    static func score(_ image:CGImage) -> Double {
        let w = 160,h = 120
        var pixels = [UInt8](repeating:0,count:w*h)
        let rendered = pixels.withUnsafeMutableBytes {buffer -> Bool in
            guard let context = CGContext(data:buffer.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w,space:CGColorSpaceCreateDeviceGray(),bitmapInfo:CGImageAlphaInfo.none.rawValue) else {return false}
            context.draw(image,in:CGRect(x:0,y:0,width:w,height:h)); return true
        }
        guard rendered else {return 0}
        var score = 0.0
        for y in 1..<h-1 {for x in 1..<w-1 {
            let i = y*w+x
            let laplacian = Double(Int(pixels[i-1])+Int(pixels[i+1])+Int(pixels[i-w])+Int(pixels[i+w])-4*Int(pixels[i]))
            score += laplacian*laplacian
        }}
        return score/Double((w-2)*(h-2))
    }
}
