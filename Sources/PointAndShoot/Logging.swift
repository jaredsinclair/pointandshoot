//
//  Logging.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Little Pie, LLC. All rights reserved.
//

import os.log

let ObligatoryLoggingPun = OSLog(subsystem: "com.niceboy.PointAndShoot", category: "Photos")

extension OSLog {

    func record(_ message: String, publicly: Bool = true) {
        if publicly {
            os_log(.default, log: self, "%{public}@", message)
        } else {
            os_log(.default, log: self, "%{private}@", message)
        }
    }

}
