//
//  VariousAndSundries.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Little Pie, LLC. All rights reserved.
//

import AVFoundation

// MARK: - CapturedPhoto

public class CapturedPhoto {
    public let capture: AVCapturePhoto
    public let fileDataRepresentation: Data
    public let livePhotoFileURL: URL?
    public let settings: AVCapturePhotoSettings

    init(capture: AVCapturePhoto, fileDataRepresentation: Data, livePhotoFileURL: URL?, settings: AVCapturePhotoSettings) {
        self.capture = capture
        self.fileDataRepresentation = fileDataRepresentation
        self.livePhotoFileURL = livePhotoFileURL
        self.settings = settings
    }
}

// MARK: - Mode

public enum Mode {
    case photo
    case video
}

// MARK: - Toggle

public enum Toggle {
    case on, off

    var boolValue: Bool {
        switch self {
        case .on: return true
        case .off: return false
        }
    }

}

// MARK: - AutoToggle

public enum AutoToggle {
    case on, off, auto
}

// MARK: - Camera

public enum Camera {
    case dual
    case dualWide
    case triple
    case wide
    case ultraWide
    case telephoto
    case trueDepth

    public static var defaultFrontPreferences: [Camera] {
        [ .wide, .telephoto, .ultraWide,
          .triple, .dual, .dualWide,
          .trueDepth
        ]
    }

    public static var defaultBackPreferences: [Camera] {
        [ .trueDepth, .wide,
          .telephoto, .ultraWide,
          .triple, .dual, .dualWide
        ]
    }

    public var lens: Lens {
        switch self {
        case .dual, .dualWide, .triple: return .adjustable
        case .wide: return .wide
        case .ultraWide: return .ultraWide
        case .telephoto: return .telephoto
        case .trueDepth: return .wide // Right?
        }
    }

    public var deviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .dual: return .builtInDualCamera
        case .dualWide: return .builtInDualWideCamera
        case .triple: return .builtInTripleCamera
        case .wide: return .builtInWideAngleCamera
        case .ultraWide: return .builtInUltraWideCamera
        case .telephoto: return .builtInTelephotoCamera
        case .trueDepth: return .builtInTrueDepthCamera
        }
    }

}

extension AVCaptureDevice {

    var cameraType: Camera? {
        switch deviceType {
        case .builtInWideAngleCamera: return .wide
        case .builtInTelephotoCamera: return .telephoto
        case .builtInUltraWideCamera: return .ultraWide
        case .builtInTripleCamera: return .triple
        case .builtInDualCamera: return .dual
        case .builtInDualWideCamera: return .dualWide
        case .builtInTrueDepthCamera: return .trueDepth
        default: return nil
        }
    }

}

// MARK: - Lens

public enum Lens {
    case wide, ultraWide, telephoto, adjustable
}

// MARK: - Body Position

public enum BodyPosition {
    case front, back

    var opposite: BodyPosition {
        switch self {
        case .front: return .back
        case .back: return .front
        }
    }
}

extension AVCaptureDevice.Position {

    var bodyPosition: BodyPosition {
        switch self {
        case .front: return .front
        case .back, .unspecified: return .back
        @unknown default: return .back
        }
    }

}
