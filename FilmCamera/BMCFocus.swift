import CoreImage
import Foundation

enum BMCFocusColor: String, Codable, CaseIterable, Identifiable {
    case white, black, red, green, blue
    var id: String { rawValue }
    var vector: CIVector {
        switch self {
        case .white: return CIVector(x: 1, y: 1, z: 1)
        case .black: return CIVector(x: 0, y: 0, z: 0)
        case .red: return CIVector(x: 1, y: 0, z: 0)
        case .green: return CIVector(x: 0, y: 1, z: 0)
        case .blue: return CIVector(x: 0, y: 0, z: 1)
        }
    }
}
struct BMCFocusOptions: Codable, Equatable {
    var enabled = false
    var coloredLines = true
    var value = 75.0
    var color: BMCFocusColor = .red
}

enum BMCFocus {
    // Weights and thresholds from the supplied APK's focus_assist_effect.glsl.
    private static let kernel = CIKernel(source: """
    kernel vec4 bmcFocus(sampler image, sampler edges, float value, float colored, vec3 lineColor) {
        vec2 p = samplerTransform(edges, destCoord());
        vec2 dx = samplerTransform(edges, destCoord() + vec2(1.0, 0.0)) - p;
        vec2 dy = samplerTransform(edges, destCoord() + vec2(0.0, 1.0)) - p;
        float e = 0.0;
        e += -sample(edges,p-2.0*dx-2.0*dy).r - 3.0*sample(edges,p-dx-2.0*dy).r - 4.0*sample(edges,p-2.0*dy).r - 3.0*sample(edges,p+dx-2.0*dy).r - sample(edges,p+2.0*dx-2.0*dy).r;
        e += -3.0*sample(edges,p-2.0*dx-dy).r + 6.0*sample(edges,p-dy).r - 3.0*sample(edges,p+2.0*dx-dy).r;
        e += -4.0*sample(edges,p-2.0*dx).r + 6.0*sample(edges,p-dx).r + 20.0*sample(edges,p).r + 6.0*sample(edges,p+dx).r - 4.0*sample(edges,p+2.0*dx).r;
        e += -3.0*sample(edges,p-2.0*dx+dy).r + 6.0*sample(edges,p+dy).r - 3.0*sample(edges,p+2.0*dx+dy).r;
        e += -sample(edges,p-2.0*dx+2.0*dy).r - 3.0*sample(edges,p-dx+2.0*dy).r - 4.0*sample(edges,p+2.0*dy).r - 3.0*sample(edges,p+dx+2.0*dy).r - sample(edges,p+2.0*dx+2.0*dy).r;
        vec4 color = sample(image, samplerCoord(image));
        float threshold = value * 0.04;
        if (colored > 0.5) return vec4(mix(color.rgb, lineColor, step(5.5 - threshold, abs(e))), color.a);
        return vec4(color.rgb + vec3(e * threshold / 4.0) * step(3.5 - threshold, abs(e)), color.a);
    }
    """)
    static func render(_ image: CIImage, source: CIImage, options: BMCFocusOptions) throws -> CIImage {
        guard options.enabled else { return image }
        guard let kernel, let result = kernel.apply(extent: image.extent, roiCallback: { index, rect in index == 1 ? rect.insetBy(dx: -2, dy: -2) : rect }, arguments: [image, source, min(100, max(0, options.value)), options.coloredLines ? 1.0 : 0.0, options.color.vector]) else {
            throw PortError.message("Focus monitoring could not be compiled.")
        }
        return result
    }
}
