//
//  CapturedPhoto.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/31/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import AVFoundation
import UIKit

public class CapturedPhoto {
    public let capture: AVCapturePhoto
    public let fileDataRepresentation: Data
    public let livePhotoFileURL: URL?
    public let settings: AVCapturePhotoSettings
    public let originalImage: UIImage
    public let previewImage: UIImage?

    init?(capture: AVCapturePhoto, livePhotoFileURL: URL?, settings: AVCapturePhotoSettings, userOrientation: AVCaptureVideoOrientation) {
        guard let data = capture.fileDataRepresentation() else { return nil }
        guard let cgImage = capture.cgImageRepresentation() else { return nil }
        let orientation = UIImage.Orientation(orientation: userOrientation)
        let image = UIImage(cgImage: cgImage.takeUnretainedValue(), scale: 1, orientation: orientation)
        self.capture = capture
        self.fileDataRepresentation = data
        self.livePhotoFileURL = livePhotoFileURL
        self.settings = settings
        self.originalImage = image.withNormalizedOrientation() ?? image
        self.previewImage = {
            guard let preview = capture.previewCGImageRepresentation() else { return nil }
            let image = UIImage(cgImage: preview.takeUnretainedValue(), scale: 1, orientation: orientation)
            return image.withNormalizedOrientation() ?? image
        }()
    }
}

extension UIImage.Orientation {

    init(orientation: AVCaptureVideoOrientation) {
        switch orientation {
        case .portrait: self = .right
        case .portraitUpsideDown: self = .left
        case .landscapeRight: self = .down
        case .landscapeLeft: self = .up
        @unknown default: self = .up
        }
    }

    init(orientation: CGImagePropertyOrientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }

    init?(cgRaw raw: UInt32) {
        if let cgOrientation = CGImagePropertyOrientation(rawValue: raw) {
            self.init(orientation: cgOrientation)
        } else {
            return nil
        }
    }

}
