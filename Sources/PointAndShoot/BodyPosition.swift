//
//  BodyPosition.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import AVFoundation

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
