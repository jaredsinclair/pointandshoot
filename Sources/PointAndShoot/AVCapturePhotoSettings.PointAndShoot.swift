//
//  AVCapturePointAndShoot.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Little Pie, LLC. All rights reserved.
//

import AVFoundation

extension AVCapturePhotoSettings {

    struct Options {
        let livePhotos: Toggle?
        let flash: AutoToggle?
        let quality: AVCapturePhotoOutput.QualityPrioritization
    }

    convenience init(camera: AVCaptureDevice, output: AVCapturePhotoOutput, options: Options) {
        if output.availablePhotoCodecTypes.contains(.hevc) {
            self.init(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            self.init()
        }

        if let flash = options.flash, camera.isFlashAvailable {
            flashMode = flash.flashMode
        } else {
            flashMode = .off
        }

        isHighResolutionPhotoEnabled = true

        if !__availablePreviewPhotoPixelFormatTypes.isEmpty {
            let key = kCVPixelBufferPixelFormatTypeKey as String
            let value = __availablePreviewPhotoPixelFormatTypes.first!
            previewPhotoFormat = [key : value]
        }

        if options.livePhotos == .on && output.isLivePhotoCaptureSupported {
            let livePhotoMovieFileName = NSUUID().uuidString
            let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
            livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
        }

        photoQualityPrioritization = options.quality
    }

}

private extension AutoToggle {

    var flashMode: AVCaptureDevice.FlashMode {
        switch self {
        case .on: return .on
        case .off: return .off
        case .auto: return .auto
        }
    }

}
