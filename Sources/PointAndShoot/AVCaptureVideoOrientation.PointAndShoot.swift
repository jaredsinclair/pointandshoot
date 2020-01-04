//
//  AVCaptureVideoOrientation.PointAndShoot.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import AVFoundation
import UIKit

extension AVCaptureVideoOrientation {

    public var interfaceOrientation: UIInterfaceOrientation {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return .portrait
        }
    }

}

extension UIInterfaceOrientation {

    var videoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        default: return .portrait
        }
    }

}
