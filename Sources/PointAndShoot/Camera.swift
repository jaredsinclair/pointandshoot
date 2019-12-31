//
//  Camera.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/31/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import AVFoundation

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
