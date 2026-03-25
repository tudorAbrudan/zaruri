//
//  ShakeMotionManager.swift
//  zaruri
//

import Foundation
import CoreMotion

/// Simple accelerometer-based shake detector.
/// Publishes a boolean flag when device movement exceeds a threshold.
final class ShakeMotionManager: ObservableObject {

    private let motionManager = CMMotionManager()

    @Published var isShaking: Bool = false

    /// Rough acceleration magnitude threshold above gravity to consider it a shake.
    private let threshold: Double = 2.5
    /// Lower threshold to stop reporting shake (prevents rapid flip-flop).
    private let hysteresis: Double = 1.8
    private let updateInterval: TimeInterval = 1.0 / 30.0

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let accel = data?.acceleration else { return }
            // Magnitude of acceleration vector.
            let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)

            if !self.isShaking, magnitude > self.threshold {
                self.isShaking = true
            } else if self.isShaking, magnitude < self.hysteresis {
                self.isShaking = false
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
        isShaking = false
    }
}

