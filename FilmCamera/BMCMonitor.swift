import CoreImage
import Foundation

/// Monitoring controls affect the viewfinder only, never the recorded movie.
struct BMCMonitorOptions: Codable, Equatable {
    var falseColor = false
    var zebra = false
    var zebraThreshold = 0.95
    var midGray: BMCMonitor.MidGray = .off
}

enum BMCMonitor {
    enum Band { case red, yellow, pink, green, blue, purple, gray }
    enum MidGray: String, Codable, CaseIterable, Identifiable {
        case off, middle, plusOne
        var id: String { rawValue }
        var title: String { switch self { case .off: return "Off"; case .middle: return "Middle gray"; case .plusOne: return "Middle gray +1" } }
        var code: Double { switch self { case .off: return 0; case .middle: return 1; case .plusOne: return 2 } }
    }
    static func falseColor(lightness: Double) -> Band {
        if lightness > 0.96820304 { return .red }
        if lightness > 0.89859341 { return .yellow }
        if lightness > 0.67639759 { return .gray }
        if lightness > 0.61389759 { return .pink }
        if lightness > 0.50318239 { return .gray }
        if lightness > 0.45974489 { return .green }
        if lightness > 0.22387647 { return .gray }
        if lightness > 0.15487244 { return .blue }
        return .purple
    }
    static func rec709Lightness(red: Double, green: Double, blue: Double) -> Double {
        func decode(_ value: Double) -> Double {
            value <= 0.081 ? value / 4.5 : pow((value + 0.099) / 1.099, 1 / 0.45)
        }
        let y = decode(red) * 0.212639 + decode(green) * 0.715169 + decode(blue) * 0.072192
        return (y <= 0.008856451679036 ? y * 903.2962962962963 : pow(y, 1 / 3) * 116 - 16) / 100
    }
    static func zebraApplies(luminance: Double, threshold: Double, midGray: MidGray) -> Bool {
        if luminance >= threshold { return true }
        switch midGray {
        case .off: return false
        case .middle: return luminance >= 0.39550781 && luminance < 0.41894531
        case .plusOne: return luminance >= 0.51171875 && luminance < 0.53417969
        }
    }

    // The Android shader uses a color-space-specific luminance LUT. This first
    // implementation uses its documented Rec. 709 equation for the preview.
    private static let kernel = CIKernel(source: """
    float linear709(float v) {
        return v <= 0.081 ? v / 4.5 : pow((v + 0.099) / 1.099, 1.0 / 0.45);
    }
    kernel vec4 bmcMonitor(sampler image, float falseColor, float zebra, float threshold, float midGray) {
        vec4 c = sample(image, samplerCoord(image));
        float y = dot(vec3(linear709(c.r), linear709(c.g), linear709(c.b)), vec3(0.212639, 0.715169, 0.072192));
        float l = (y <= 0.008856451679036 ? y * 903.2962962962963 : pow(y, 1.0 / 3.0) * 116.0 - 16.0) / 100.0;
        vec3 result = c.rgb;
        if (falseColor > 0.5) {
            result = vec3(l);
            if (l > 0.96820304) result = vec3(0.886, 0.055, 0.012);
            else if (l > 0.89859341) result = vec3(0.992, 0.976, 0.106);
            else if (l > 0.67639759) result = vec3(l);
            else if (l > 0.61389759) result = vec3(0.949, 0.710, 0.741);
            else if (l > 0.50318239) result = vec3(l);
            else if (l > 0.45974489) result = vec3(0.306, 1.0, 0.145);
            else if (l > 0.22387647) result = vec3(l);
            else if (l > 0.15487244) result = vec3(0.118, 0.0, 0.863);
            else result = vec3(1.0, 0.059, 1.0);
        }
        float middle = midGray < 0.5 ? 0.0 : (midGray < 1.5 ? step(0.39550781, l) * (1.0 - step(0.41894531, l)) : step(0.51171875, l) * (1.0 - step(0.53417969, l)));
        float stripe = step(8.0, mod(destCoord().x + destCoord().y, 16.0));
        if (zebra > 0.5 && stripe * max(step(threshold, l), middle) > 0.5) result = vec3(1.0);
        return vec4(result, c.a);
    }
    """)
    static func render(_ image: CIImage, options: BMCMonitorOptions) throws -> CIImage {
        guard options.falseColor || options.zebra else { return image }
        guard let kernel, let result = kernel.apply(extent: image.extent, roiCallback: { _, rect in rect }, arguments: [image, options.falseColor ? 1.0 : 0.0, options.zebra ? 1.0 : 0.0, min(1, max(0, options.zebraThreshold)), options.midGray.code]) else {
            throw PortError.message("Exposure monitoring could not be compiled.")
        }
        return result
    }
}
