//
//  CaptureViewController.swift
//  SampleProject
//
//  Created by Jared Sinclair on 1/2/20.
//  Copyright © 2020 Nice Boy, LLC. All rights reserved.
//

// Remove me!

import PointAndShoot
import Combine
import UIKit
import Photos

class CameraViewController: UIViewController {

    @IBOutlet var thumbnail: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var focusReticle: UIView!
    @IBOutlet var previewContainer: UIView!
    @IBOutlet var previewHeight: NSLayoutConstraint!
    @IBOutlet var focusReticleCenterX: NSLayoutConstraint!
    @IBOutlet var focusReticleCenterY: NSLayoutConstraint!
    @IBOutlet var transformableControls: [UIView]!

    let session = CaptureSession()
    var subscriptions = Set<AnyCancellable>()
    var videoAspectRatio: CGFloat = 9 / 16 {
        didSet { updateVideoPreviewConstraints() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(session.preview)
        previewContainer.addConstrainedSubview(session.preview.view)
        session.preview.didMove(toParent: self)

        // Rotate the controls relative to the current video orientation,
        // independently of whatever the current **interface** orientation is.
        // This is how you can limit your app to a portrait orientation without
        // losing the ability to present a Camera.app type experience.
        session.$videoOrientation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] o in self?.updateControlOrientation(relativeTo: o) }
            .store(in: &subscriptions)

        // The presence of items in `photoCaptureItems` indicates how many in-
        // progress captures there are in a pending state. This sample app
        // simply treats a non-zero number of items as a trigger to show an
        // activity indicator. Your app may want to track photo progress for
        // each item individually (their states are published, too).
        session.$photoCaptureItems
            .receive(on: OperationQueue.main)
            .sink {
                if $0.isEmpty && self.activityIndicator.isAnimating {
                    self.activityIndicator.stopAnimating()
                } else if !$0.isEmpty && !self.activityIndicator.isAnimating {
                    self.activityIndicator.startAnimating()
                }
            }
            .store(in: &subscriptions)

        // Subscribe to dimension updates to constrain your container view as
        // needed.
        session.$dimensions
            .map { dimensions -> CGFloat in
                let fallback: CGFloat = 9 / 16
                guard let dimensions = dimensions else { return fallback }
                guard dimensions.height > 0 else { return fallback }
                guard dimensions.width > 0 else { return fallback }
                return CGFloat(dimensions.height) / CGFloat(dimensions.width)
            }
            .receive(on: OperationQueue.main)
            .assign(to: \.videoAspectRatio, on: self)
            .store(in: &subscriptions)

        // The big one: subscribe to the photo publisher, if nothing else, in
        // order to receive photos as they're captured. This sample app uses a
        // convenient extension method on PHPhotoLibrary to save each capture to
        // the user's camera roll.
        session.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] capture in
                PHPhotoLibrary.save(capture)
                self?.thumbnail.image = capture.previewImage
            }
            .store(in: &subscriptions)

        // You must call `start()` for video previewing to begin.
        session.start()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateVideoPreviewConstraints()
    }

    @IBAction func takePhoto(_ sender: UIButton) {
        session.capturePhoto()
    }

    @IBAction func focusAndExpose(_ sender: UITapGestureRecognizer) {

        // You must obtain a point in the coordinates of the session preview.
        let point = sender.location(in: sender.view)
        let focalPoint = sender.view!.convert(point, to: session.preview.view)

        // This method both auto-focuses and auto-exposes at the supplied point.
        // That focus and exposure are abandoned upon significant subject changes.
        session.focusAndExpose(atPreviewPoint: focalPoint)

        // You're on your own to display UI at the tapped focal point.
        let reticlePoint = sender.view!.convert(point, to: view)
        focusReticle.alpha = 1
        focusReticleCenterX.constant = reticlePoint.x
        focusReticleCenterY.constant = reticlePoint.y
        UIView.animate(withDuration: 1, delay: 0, options: .curveLinear, animations: {
            self.focusReticle.alpha = 0
        }, completion: nil)
    }

    func updateControlOrientation(relativeTo orientation: AVCaptureVideoOrientation) {
        let transform = orientation.controlTransform
        let animator = UIViewPropertyAnimator(
            duration: 0,
            timingParameters: UISpringTimingParameters())
        animator.addAnimations {
            self.transformableControls.forEach {
                $0.transform = transform
            }
        }
        animator.startAnimation()
    }

    func updateVideoPreviewConstraints() {
        previewHeight.constant = view.width / videoAspectRatio
    }

}

typealias Radians = CGFloat

extension Int {

    var radians: CGFloat {
        return CGFloat(self) * .pi / 180
    }

    var radiansDouble: Double {
        return Double(self) * .pi / 180
    }

}

extension AVCaptureVideoOrientation {

    var controlTransform: CGAffineTransform {
        switch self {
        case .portrait: return .identity
        case .landscapeLeft: return CGAffineTransform(rotationAngle: 90.radians)
        case .landscapeRight: return CGAffineTransform(rotationAngle: -90.radians)
        case .portraitUpsideDown: return CGAffineTransform(rotationAngle: 180.radians)
        default: return .identity
        }
    }

}
