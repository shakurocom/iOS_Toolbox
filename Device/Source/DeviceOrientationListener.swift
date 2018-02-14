//
// Copyright (c) 2017 Shakuro (https://shakuro.com/)
// Vlad Onipchenko
//

import Foundation
import  UIKit
import CoreMotion

public class DeviceOrientationListener {

    private static let accelerationThreshold = 0.75;

    private let isSimulatorMode: Bool
    private let motionManager: CMMotionManager?
    private let motionQueue: OperationQueue?
    private var _currentOrientation: UIDeviceOrientation = UIDeviceOrientation.unknown

    // MARK: - Initialization

    public init(accelerometerUpdateInterval: TimeInterval = 0.1) {
        isSimulatorMode = DeviceType.current == .simulator
        _currentOrientation = UIDevice.current.orientation
        if isSimulatorMode {
            motionManager = nil
            motionQueue = nil
        } else {
            motionManager = CMMotionManager()
            motionManager?.accelerometerUpdateInterval = accelerometerUpdateInterval
            motionQueue = OperationQueue()
            motionQueue?.name = "com.shakuro.DeviceOrientationListener.motionQueue"
            motionQueue?.maxConcurrentOperationCount = 1
        }
    }

    deinit {
        endListeningDeviceOrientation()
    }

    // MARK: - Public

    public var currentOrientation: UIDeviceOrientation {
        if isSimulatorMode {
            return UIDevice.current.orientation
        } else {
            return _currentOrientation
        }
    }

    public func beginListeningDeviceOrientation() {
        guard !isSimulatorMode,
            let manager = motionManager,
            manager.isAccelerometerAvailable,
            !manager.isAccelerometerActive,
            let queue = motionQueue
            else {
                return
        }
        manager.startAccelerometerUpdates(to: queue, withHandler: { [weak self] (accelerometerData: CMAccelerometerData?, error: Error?) in
            guard let actualSelf = self, error == nil, let acceleration = accelerometerData?.acceleration else {
                return
            }
            if acceleration.x >= DeviceOrientationListener.accelerationThreshold {
                actualSelf._currentOrientation = UIDeviceOrientation.landscapeRight
            } else if (acceleration.x <= -DeviceOrientationListener.accelerationThreshold) {
                actualSelf._currentOrientation = UIDeviceOrientation.landscapeLeft;
            } else if (acceleration.y <= -DeviceOrientationListener.accelerationThreshold) {
                actualSelf._currentOrientation = UIDeviceOrientation.portrait;
            } else if (acceleration.y >= DeviceOrientationListener.accelerationThreshold) {
                actualSelf._currentOrientation = UIDeviceOrientation.portraitUpsideDown;
            }
        })
    }

    public func endListeningDeviceOrientation() {
        motionManager?.stopAccelerometerUpdates()
    }

}
