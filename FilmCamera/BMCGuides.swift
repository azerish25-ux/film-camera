import SwiftUI

enum BMCGuideRatio: String, Codable, CaseIterable, Identifiable {
    case cinema276 = "2.76:1", cinema24 = "2.4:1", cinema239 = "2.39:1", cinema235 = "2.35:1"
    case wide = "2:1", cinema185 = "1.85:1", television = "14:9", classic = "4:3"
    case square = "1:1", portrait45 = "4:5", portrait = "9:16"
    var id: String { rawValue }
    var value: CGFloat {
        switch self {
        case .cinema276: return 2.76
        case .cinema24: return 2.4
        case .cinema239: return 2.39
        case .cinema235: return 2.35
        case .wide: return 2
        case .cinema185: return 1.85
        case .television: return 14.0 / 9.0
        case .classic: return 4.0 / 3.0
        case .square: return 1
        case .portrait45: return 4.0 / 5.0
        case .portrait: return 9.0 / 16.0
        }
    }
}

struct BMCGuideOptions: Codable, Equatable {
    var framing = false
    var ratio: BMCGuideRatio = .wide
    var thirds = false
    var crosshairs = false
    var centerDot = false
    var opacity = 0.75
}

enum BMCGuideGeometry {
    static func frame(in bounds: CGRect, ratio: CGFloat) -> CGRect {
        guard bounds.width > 0, bounds.height > 0, ratio.isFinite, ratio > 0 else { return .zero }
        let width = min(bounds.width, bounds.height * ratio)
        let height = width / ratio
        return CGRect(x: bounds.midX - width / 2, y: bounds.midY - height / 2, width: width, height: height)
    }
}

struct BMCGuideOverlay: View {
    let imageSize: CGSize
    let options: BMCGuideOptions
    var body: some View {
        Canvas { context, size in
            let image = BMCGuideGeometry.frame(in: CGRect(origin: .zero, size: size), ratio: imageSize.width / max(1, imageSize.height))
            guard image.width > 0, image.height > 0 else { return }
            var path = Path()
            if options.framing { path.addRect(BMCGuideGeometry.frame(in: image, ratio: options.ratio.value)) }
            if options.thirds {
                for fraction in [CGFloat(1.0 / 3.0), CGFloat(2.0 / 3.0)] {
                    let x = image.minX + image.width * fraction, y = image.minY + image.height * fraction
                    path.move(to: CGPoint(x: x, y: image.minY)); path.addLine(to: CGPoint(x: x, y: image.maxY))
                    path.move(to: CGPoint(x: image.minX, y: y)); path.addLine(to: CGPoint(x: image.maxX, y: y))
                }
            }
            if options.crosshairs {
                path.move(to: CGPoint(x: image.midX - 12, y: image.midY)); path.addLine(to: CGPoint(x: image.midX + 12, y: image.midY))
                path.move(to: CGPoint(x: image.midX, y: image.midY - 12)); path.addLine(to: CGPoint(x: image.midX, y: image.midY + 12))
            }
            if options.centerDot { path.addEllipse(in: CGRect(x: image.midX - 2, y: image.midY - 2, width: 4, height: 4)) }
            context.stroke(path, with: .color(.white.opacity(min(1, max(0, options.opacity)))), lineWidth: 1)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
