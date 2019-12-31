//
//  VariousAndSundries.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

public enum Toggle {
    case on, off

    var boolValue: Bool {
        switch self {
        case .on: return true
        case .off: return false
        }
    }

}
