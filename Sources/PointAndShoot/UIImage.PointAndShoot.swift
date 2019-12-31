//
//  UIImage.PointAndShoot.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/31/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import UIKit

extension UIImage {

    // With gratitude: https://gist.github.com/schickling/b5d86cb070130f80bb40
    func withNormalizedOrientation() -> UIImage? {

        // The .up orientation is the default; no changes are required.
        guard imageOrientation != UIImage.Orientation.up else { return self }

        guard let cgImage = self.cgImage else { return nil }
        guard let colorSpace = cgImage.colorSpace else { return nil }

        let contextOrNil = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = contextOrNil else { return nil }

        var transform: CGAffineTransform = CGAffineTransform.identity

        // The docs specify the orientations that require a rotation...

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }

        // ...and also those that require a flip around an axis.

        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            break
        }

        context.concatenate(transform)

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }

        guard let newCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: newCGImage, scale: 1, orientation: .up)
    }

}
