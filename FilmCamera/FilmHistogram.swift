import CoreImage
import SwiftUI

enum FilmHistogram {
    private static let context = CIContext(options:[.workingColorSpace:NSNull(),.outputColorSpace:NSNull()])
    static func values(_ image: CIImage) -> [Float] {
        guard let filter = CIFilter(name:"CIAreaHistogram",parameters:[kCIInputImageKey:image,"inputExtent":CIVector(cgRect:image.extent),"inputCount":256,"inputScale":1]), let output = filter.outputImage else {return []}
        var bins = [Float](repeating:0,count:256*4)
        bins.withUnsafeMutableBytes {context.render(output,toBitmap:$0.baseAddress!,rowBytes:256*16,bounds:CGRect(x:0,y:0,width:256,height:1),format:.RGBAf,colorSpace:nil)}
        return bins
    }
}
struct HistogramPlot: View {
    let values: [Float]
    var body: some View {
        Canvas {drawing,size in
            guard values.count == 1024 else {return}
            let maximum = max(0.000001,values.enumerated().filter {$0.offset%4 != 3}.map {$0.element}.max() ?? 1)
            let colors: [Color] = [.red,.green,.blue]
            for channel in 0..<3 {
                var path = Path()
                for bin in 0..<256 {
                    let point = CGPoint(x:size.width*CGFloat(bin)/255,y:size.height*(1-CGFloat(values[bin*4+channel]/maximum)))
                    if bin == 0 {path.move(to:point)} else {path.addLine(to:point)}
                }
                drawing.stroke(path,with:.color(colors[channel].opacity(0.85)),lineWidth:1)
            }
        }.frame(height:90).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius:6))
        .accessibilityElement(children:.ignore).accessibilityLabel("Red, green and blue histogram")
    }
}

struct CurvePlot: View {
    let x: [Double]
    let y: [Double]
    var body: some View {
        Canvas {drawing,size in
            let values = FilmCurve.samples(x:x,y:y)
            var path = Path()
            for (index,value) in values.enumerated() {
                let point = CGPoint(x:size.width*CGFloat(index)/255,y:size.height*(1-CGFloat(value)/255))
                if index == 0 {path.move(to:point)} else {path.addLine(to:point)}
            }
            drawing.stroke(path,with:.color(.white),lineWidth:1.5)
        }.frame(height:100).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius:6))
        .accessibilityLabel("Film characteristic curve")
    }
}
