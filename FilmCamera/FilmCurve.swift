import Foundation

/// Natural cubic spline used by the Android characteristic-curve editor.
enum FilmCurve {
    static func samples(x: [Double], y: [Double]) -> [Double] {
        guard x.count == y.count, x.count >= 3, zip(x,x.dropFirst()).allSatisfy({$0 < $1}), x.first == 0, x.last == 255 else {return (0...255).map(Double.init)}
        let n = x.count-1, h = (0..<x.count-1).map {x[$0+1]-x[$0]}
        var mu = [Double](repeating:0,count:n), z = [Double](repeating:0,count:n+1)
        if n > 1 {for i in 1..<n {
            let d = (x[i+1]-x[i-1])*2-h[i-1]*mu[i-1]
            mu[i] = h[i]/d
            z[i] = (((y[i+1]*h[i-1]-(x[i+1]-x[i-1])*y[i]+y[i-1]*h[i])*3/(h[i]*h[i-1]))-h[i-1]*z[i-1])/d
        }}
        var b = mu, c = z, d = mu
        for i in stride(from:n-1,through:0,by:-1) {
            c[i] = z[i]-mu[i]*c[i+1]
            b[i] = (y[i+1]-y[i])/h[i]-(2*c[i]+c[i+1])*h[i]/3
            d[i] = (c[i+1]-c[i])/(h[i]*3)
        }
        return (0...255).map {value in
            let index = min(n-1,max(0,(x.lastIndex(where:{$0 <= Double(value)}) ?? 0)))
            let delta = Double(value)-x[index]
            let interpolated = y[index]+delta*(b[index]+delta*(c[index]+delta*d[index]))
            return Double(min(255,max(0,Int(interpolated))))
        }
    }
}
