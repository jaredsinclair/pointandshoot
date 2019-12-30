//
//  UIDevice.PointAndShoot.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Little Pie, LLC. All rights reserved.
//

import AVFoundation
import UIKit

extension UIDevice {

    var videoPreviewOrientation: AVCaptureVideoOrientation? {
        guard orientation.isPortrait || orientation.isLandscape else { return nil }
        return AVCaptureVideoOrientation(deviceOrientation: orientation)
    }

}
