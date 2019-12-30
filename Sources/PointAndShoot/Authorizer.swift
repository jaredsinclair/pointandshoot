//
//  Authorizer.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import Foundation
import AVFoundation

class Authorizer {

    enum CompletionMode {
        case sync
        case async
    }

    struct CaptureAuthorization {
        fileprivate(set) var video: AVAuthorizationStatus
        fileprivate(set) var audio: AVAuthorizationStatus

        var isFullyAuthorized: Bool {
            switch (video, audio) {
            case (.authorized, .authorized): return true
            default: return false
            }
        }

        static var existing: CaptureAuthorization {
            CaptureAuthorization(
                video: AVCaptureDevice.authorizationStatus(for: .video),
                audio: AVCaptureDevice.authorizationStatus(for: .audio)
            )
        }
    }

    let existingAuthorization = CaptureAuthorization.existing

    @discardableResult
    func requestAccess(completion: @escaping (CaptureAuthorization) -> Void) -> CompletionMode {
        var videoAuthorization: AVAuthorizationStatus?
        var audioAuthorization: AVAuthorizationStatus?

        func finishIfPossible() {
            guard let video = videoAuthorization else { return }
            guard let audio = audioAuthorization else { return }
            let authorization = CaptureAuthorization(video: video, audio: audio)
            completion(authorization)
        }

        let videoMode = checkVideoStatus { status in
            OperationQueue.onMain {
                videoAuthorization = status
                finishIfPossible()
            }
        }

        let audioMode = checkAudioStatus { status in
            OperationQueue.onMain {
                audioAuthorization = status
                finishIfPossible()
            }
        }

        switch (videoMode, audioMode) {
        case (.sync, .sync): return .sync
        default: return .async
        }
    }

    private func checkVideoStatus(completion: @escaping (AVAuthorizationStatus) -> Void) -> CompletionMode {
        switch existingAuthorization.video {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted ? .authorized : .denied)
            }
            return .async
        case .authorized, .restricted, .denied:
            completion(existingAuthorization.video)
            return .sync
        @unknown default:
            completion(.denied)
            return .sync
        }
    }

    private func checkAudioStatus(completion: @escaping (AVAuthorizationStatus) -> Void) -> CompletionMode {
        switch existingAuthorization.audio {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted ? .authorized : .denied)
            }
            return .async
        case .authorized, .restricted, .denied:
            completion(existingAuthorization.audio)
            return .sync
        @unknown default:
            completion(.denied)
            return .sync
        }
    }

}
