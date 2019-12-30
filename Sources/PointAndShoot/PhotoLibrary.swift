//
//  PhotoLibrary.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Little Pie, LLC. All rights reserved.
//

import Foundation
import Photos

extension PHPhotoLibrary {

    /// Saves `photo` to the camera roll.
    ///
    /// Speaking of roll: if you need a more nuanced flow —— say you want to
    /// save the photo to a specific album —– then roll your own implementation.
    public static func save(_ photo: CapturedPhoto) {
        requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = photo.settings.processedFileType.map { $0.rawValue }
                    creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation, options: options)
                    if let livePhotoCompanionMovieURL = photo.livePhotoFileURL {
                        let livePhotoCompanionMovieFileOptions = PHAssetResourceCreationOptions()
                        livePhotoCompanionMovieFileOptions.shouldMoveFile = true
                        creationRequest.addResource(with: .pairedVideo,
                                                    fileURL: livePhotoCompanionMovieURL,
                                                    options: livePhotoCompanionMovieFileOptions)
                    }
                }, completionHandler: { _, error in
                    if let error = error {
                        ObligatoryLoggingPun.record("Error occurred while saving photo to photo library: \(error)")
                    }
                })
            } else {
                ObligatoryLoggingPun.record("Error occurred while saving photo to photo library: unauthorized.")
            }
        }
    }

}
