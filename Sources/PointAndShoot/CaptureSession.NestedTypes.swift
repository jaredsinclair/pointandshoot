//
//  CaptureSession.NestedTypes.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import AVFoundation
import Combine
import UIKit
import CoreMotion

extension CaptureSession {

    public struct Options {
        public let modes: [Mode]
        public let interfaceOrientations: Set<UIInterfaceOrientation>
        public let preferredFrontCameras: [Camera]
        public let preferredBackCameras: [Camera]
        public let autoEnableLivePhotosIfAvailable: Bool
        public let preferredInitialFlashMode: AutoToggle
        public let applicationMotionManager: CMMotionManager?

        public static let `default` = Options()

        public init(
            modes: [Mode] = [.photo],
            interfaceOrientations: Set<UIInterfaceOrientation> = [.portrait],
            preferredFrontCameras: [Camera] = Camera.defaultFrontPreferences,
            preferredBackCameras: [Camera] = Camera.defaultBackPreferences,
            autoEnableLivePhotosIfAvailable: Bool = true,
            preferredInitialFlashMode: AutoToggle = .off,
            applicationMotionManager: CMMotionManager? = nil
        ) {
            self.modes = modes
            self.interfaceOrientations = interfaceOrientations
            self.preferredFrontCameras = preferredFrontCameras
            self.preferredBackCameras = preferredBackCameras
            self.autoEnableLivePhotosIfAvailable = autoEnableLivePhotosIfAvailable
            self.preferredInitialFlashMode = preferredInitialFlashMode
            self.applicationMotionManager = applicationMotionManager
        }
    }

    public final class PhotoCaptureItem {
        public let id: Int64
        public internal(set) var state: PhotoCaptureState

        internal init(settings: AVCapturePhotoSettings) {
            id = settings.uniqueID
            state = .capturing
        }
    }

    public enum PhotoCaptureState {
        case capturing
        case continuingIndeterminately
        case finished
    }

    public enum ConfigurationError: Swift.Error {
        case unauthorized
        case noCameraFound
        case noMicrophoneFound
        case unableToAddVideoInput(Swift.Error?)
        case unableToAddAudioInput(Swift.Error?)
        case unableToAddPhotoOutput(Swift.Error?)
    }

    public struct SessionInterruption {
        public let reason: AVCaptureSession.InterruptionReason?

        public var isResumable: Bool {
            guard let reason = reason else { return false }
            switch reason {
            case .audioDeviceInUseByAnotherClient,
                 .videoDeviceInUseByAnotherClient:
                return true
            case .videoDeviceNotAvailableWithMultipleForegroundApps,
                 .videoDeviceNotAvailableDueToSystemPressure,
                 .videoDeviceNotAvailableInBackground:
                return false
            @unknown default:
                return false
            }
        }
    }

}
