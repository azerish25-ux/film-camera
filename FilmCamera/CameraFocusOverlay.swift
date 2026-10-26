import SwiftUI

struct CameraFocusOverlay: View {
    let size: CGSize
    let focus: (CGPoint) -> Void
    @State private var marker: CGPoint?
    var body: some View {
        GeometryReader {geometry in
            let scale = min(geometry.size.width/max(1,size.width),geometry.size.height/max(1,size.height))
            let width = size.width*scale,height = size.height*scale
            let x = (geometry.size.width-width)/2,y = (geometry.size.height-height)/2
            Color.clear.contentShape(Rectangle()).gesture(DragGesture(minimumDistance:0).onEnded {value in
                let point = value.location
                guard point.x >= x,point.x <= x+width,point.y >= y,point.y <= y+height else {return}
                marker = point; focus(CGPoint(x:(point.x-x)/width,y:(point.y-y)/height))
            })
            if let marker {Rectangle().stroke(.yellow,lineWidth:1).frame(width:44,height:44).position(marker).allowsHitTesting(false)}
        }.accessibilityLabel("Tap viewfinder to focus")
    }
}
