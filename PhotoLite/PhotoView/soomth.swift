//
//  soomth.swift
//  PhotoView
//
//  Created by Suxin on 2024/5/24.
//

import Foundation

public protocol Interpolator {
    associatedtype Value
    var points: [Value] { get }
    func interpolate(_ t: Float) -> Value
}

extension Interpolator {
    public func resample(interval: Float) -> [Value] {
        let count = Int(floor(Float(points.count) / interval))
        return Array(0..<count).map { interpolate(Float($0) * interval) }
    }
}

extension Interpolator where Value == Float {
    func getClippedInput(_ i: Int) -> Value {
        return points[max(0, min(i, points.count - 1))]
    }
}

public typealias InterpolateFunc<Value> = (_ t: Value) -> Value


public class CubicInterpolator: Interpolator {
    public typealias Value = Float
    public let points: [Float]
    private let tangentFactor: Float

    public init(points: [Value], tension: Float = 0.0) {
        self.points = points
        tangentFactor = 1.0 - max(0.0, min(1.0, tension))
    }

    // Cardinal spline with tension 0.5)
    private func getTangent(_ k: Int) -> Value {
        return tangentFactor * (getClippedInput(k + 1) - getClippedInput(k - 1)) / 2
    }

    public func interpolate(_ t: Float) -> Value {
        let k = Int(floor(t))
        let m = [getTangent(k), getTangent(k + 1)]
        let p = [getClippedInput(k), getClippedInput(k + 1)]
        let t1 = t - Float(k)
        let t2 = t1 * t1
        let t3 = t1 * t2
        return (2 * t3 - 3 * t2 + 1) * p[0] +
            (t3 - 2 * t2 + t1) * m[0] +
            (-2 * t3 + 3 * t2) * p[1] +
            (t3 - t2) * m[1]
    }
}
