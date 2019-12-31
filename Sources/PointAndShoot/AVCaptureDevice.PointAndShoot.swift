//
//  AVCaptureDevice.PointAndShoot.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Little Pie, LLC. All rights reserved.
//

import AVFoundation
import Etcetera

extension AVCaptureDevice {

    func focusAndExpose(at focalPoint: CGPoint, focus: AVCaptureDevice.FocusMode, exposure: AVCaptureDevice.ExposureMode, monitorSubjectAreaChanges: Bool) {
        do {
            try lockForConfiguration()

            if isFocusPointOfInterestSupported && isFocusModeSupported(focus) {
                focusPointOfInterest = focalPoint
                focusMode = focus
            }

            if isExposurePointOfInterestSupported && isExposureModeSupported(exposure) {
                exposurePointOfInterest = focalPoint
                exposureMode = exposure
            }

            isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChanges
            unlockForConfiguration()
        } catch {
            ObligatoryLoggingPun.error("Could not lock device for configuration: \(error)")
        }
    }

}
