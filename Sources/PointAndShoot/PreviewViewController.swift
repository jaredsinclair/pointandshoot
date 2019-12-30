//
//  PreviewViewController.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Little Pie, LLC. All rights reserved.
//

import AVFoundation
import Combine
import UIKit

final class PreviewViewController: UIViewController {

    var session: AVCaptureSession? {
        get { previewView.session }
        set { previewView.session = newValue }
    }

    private var previewView: PreviewView {
        view as! PreviewView
    }

    private var subscriptions = Set<AnyCancellable>()
    private let supportedOrientations: Set<AVCaptureVideoOrientation>

    init(supportedOrientations orientations: Set<UIInterfaceOrientation>) {
        supportedOrientations = Set(orientations.map(\.videoOrientation))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    override func loadView() {
        view = PreviewView(frame: UIScreen.main.bounds)

        NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in self?.updateOrientation() }
            .store(in: &subscriptions)
    }

    func captureDevicePointConverted(from point: CGPoint) -> CGPoint {
        previewView.previewLayer.captureDevicePointConverted(fromLayerPoint: point)
    }

    private func updateOrientation() {
        guard let orientation = UIDevice.current.videoPreviewOrientation else { return }
        guard supportedOrientations.contains(orientation) else {
            ObligatoryLoggingPun.record("Unsupported orientation will be ignored: \(orientation.pointAndShootDescription)")
            return
        }
        previewView.previewLayer.connection?.videoOrientation = orientation
    }

}

extension AVCaptureVideoOrientation {

    var pointAndShootDescription: String {
        switch self {
        case .portrait: return ".portrait"
        case .portraitUpsideDown: return ".portraitUpsideDown"
        case .landscapeLeft: return ".landscapeLeft"
        case .landscapeRight: return ".landscapeRight"
        default: return "<unknown>"
        }
    }

}
