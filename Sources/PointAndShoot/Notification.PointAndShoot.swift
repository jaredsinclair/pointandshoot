//
//  Notification.PointAndShoot.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import AVFoundation
import Foundation

extension Notification {

    var sessionInterruption: CaptureSession.SessionInterruption? {
        let key = AVCaptureSessionInterruptionReasonKey
        guard let userInfoValue = userInfo?[key] as AnyObject? else { return nil }
        let reasonIntegerValue = userInfoValue.integerValue ?? 0
        let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue)
        return CaptureSession.SessionInterruption(reason: reason)
    }

}
