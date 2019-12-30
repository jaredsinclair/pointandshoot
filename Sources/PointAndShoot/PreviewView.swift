//
//  CameraController.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/26/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import UIKit
import AVFoundation

final class PreviewView: UIView {

    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }

    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

}
