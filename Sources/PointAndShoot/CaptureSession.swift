//
//  CaptureSession.swift
//  PointAndShoot
//
//  Created by Jared Sinclair on 12/30/19.
//  Copyright © 2019 Nice Boy, LLC. All rights reserved.
//

import AVFoundation
import Combine
import UIKit
import Etcetera
import OrientationObserver

public final class CaptureSession: NSObject {

    // MARK: - Public Properties (Constant)

    public let preview: UIViewController
    public let publisher: AnyPublisher<CapturedPhoto, Never>

    // MARK: - Public Properties (Published)

    @Published public private(set) var mode: Mode
    @Published public private(set) var photoCaptureItems: [PhotoCaptureItem] = []
    @Published public private(set) var livePhotosInProgress: Int = 0
    @Published public private(set) var availableFrontCameras: [Camera] = []
    @Published public private(set) var availableBackCameras: [Camera] = []
    @Published public private(set) var bodyPosition: BodyPosition = .back
    @Published public private(set) var currentCamera: AVCaptureDevice?
    @Published public private(set) var configurationError: ConfigurationError?
    @Published public private(set) var livePhotos: Toggle?
    @Published public private(set) var flash: AutoToggle?
    @Published public private(set) var dimensions: CMVideoDimensions?
    @Published public private(set) var sessionInterruption: SessionInterruption?

    // MARK: - Private Properties

    private let options: Options
    private let session = AVCaptureSession()
    private let queue = OperationQueue.serialQueue()
    private let authorizer = Authorizer()
    private let frontCameraDiscovery: AVCaptureDevice.DiscoverySession
    private let backCameraDiscovery: AVCaptureDevice.DiscoverySession
    private let photoOutput = AVCapturePhotoOutput()
    private let passthroughSubject: PassthroughSubject<CapturedPhoto, Never>
    private let orientationObserver: OrientationObserver
    private var processors: [Int64: PhotoProcessor] = [:]
    private var currentInput: AVCaptureDeviceInput?
    private var currentCameraSubscriptions = Set<AnyCancellable>()
    private var sessionSubscriptions = Set<AnyCancellable>()
    private var lifetimeSubscriptions = Set<AnyCancellable>()
    private var interfaceOrientation: UIInterfaceOrientation

    // MARK: - Init / Deinit

    public init(options: Options = .default) {
        precondition(!options.modes.isEmpty, "You must provide at least one mode.")
        precondition(!options.interfaceOrientations.isEmpty, "You must provide at least one supported interface orientation.")
        self.options = options
        mode = options.modes.first!
        preview = PreviewViewController(supportedOrientations: options.interfaceOrientations)
        let subject = PassthroughSubject<CapturedPhoto, Never>()
        passthroughSubject = subject
        publisher = passthroughSubject.eraseToAnyPublisher()
        frontCameraDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: options.preferredFrontCameras.map(\.deviceType),
            mediaType: .video,
            position: .front
        )
        backCameraDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: options.preferredBackCameras.map(\.deviceType),
            mediaType: .video,
            position: .back
        )
        orientationObserver = OrientationObserver(
            applicationMotionManager: options.applicationMotionManager
        )
        interfaceOrientation = options.interfaceOrientations.first!
        super.init()
        orientationObserver
            .receive(on: queue)
            .filter { options.interfaceOrientations.contains($0) }
            .assign(to: \.interfaceOrientation, on: self)
            .store(in: &lifetimeSubscriptions)
        availableFrontCameras = frontCameraDiscovery.devices.compactMap { $0.cameraType }
        availableBackCameras = backCameraDiscovery.devices.compactMap { $0.cameraType }
    }

    // MARK: - Public Methods

    public func start() {
        assert(OperationQueue.isMain)
        orientationObserver.start()
        if authorizer.existingAuthorization.isFullyAuthorized {
            authorizationCheckPassed()
        } else {
            authorizer.requestAccess { [weak self] updatedAuthorization in
                if updatedAuthorization.isFullyAuthorized {
                    self?.authorizationCheckPassed()
                } else {
                    self?.configurationError = .unauthorized
                }
            }
        }
    }

    public func resume() {
        // stuf
    }

    public func stop() {
        orientationObserver.stop()
        queue.asap {
            self.sessionSubscriptions.removeAll()
            self.currentCameraSubscriptions.removeAll()
            self.currentCamera = nil
            self.currentInput = nil
            self.session.stopRunning()
        }
    }

    public func toggleLivePhotos(_ newValue: Toggle) {
        let canEnableLivePhotos = livePhotos != nil
        switch (canEnableLivePhotos, newValue) {
        case (true, .on):
            livePhotos = .on
        case (true, .off):
            livePhotos = .off
        case (false, _):
            livePhotos = nil
        }
    }

    public func toggleFlash(_ newValue: AutoToggle) {
        let canEnableFlash = flash != nil
        switch (canEnableFlash, newValue) {
        case (true, .on):
            flash = .on
        case (true, .off):
            flash = .off
        case (true, .auto):
            flash = .auto
        case (false, _):
            flash = nil
        }
    }

    public func toggleBetweenFrontAndBackCameras() {
        queue.asap {
            self.toggleBetweenFrontAndBackCameras_queued()
        }
    }

    public func focusAndExpose(atPreviewPoint previewPoint: CGPoint) {
        assert(OperationQueue.isMain)
        let focalPoint = (preview as! PreviewViewController)
            .captureDevicePointConverted(from: previewPoint)
        queue.asap {
            self.currentCamera?.focusAndExpose(
                at: focalPoint,
                focus: .autoFocus,
                exposure: .autoExpose,
                monitorSubjectAreaChanges: true
            )
        }
    }

    public func capturePhoto() {
        assert(OperationQueue.isMain)
        queue.addOperation { [weak self] in
            self?.capturePhoto_queued()
        }
    }

    // MARK: - Private Methods (Configuration)

    private func authorizationCheckPassed() {
        assert(OperationQueue.isMain)

        (preview as! PreviewViewController).session = session

        queue.addOperation { [weak self] in
            guard let self = self else { return }
            do {
                try self.performInitialSessionConfiguration_queued()
                self.session.startRunning()
            } catch {
                self.configurationError = (error as! ConfigurationError)
            }
        }
    }

    /// - throws: ConfigurationError
    private func performInitialSessionConfiguration_queued() throws {
        assert(queue.isCurrent)

        let firstAvailableVideoDevice: AVCaptureDevice? = {
            switch bodyPosition {
            case .front: return frontCameraDiscovery.devices.first
            case .back: return backCameraDiscovery.devices.first
            }
        }()

        guard let videoDevice = firstAvailableVideoDevice else {
            throw ConfigurationError.noCameraFound
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        switch mode {
        case .photo:
            session.sessionPreset = .photo
        case .video:
            session.sessionPreset = .high
        }

        try addVideoInput_queued(videoDevice: videoDevice)
        try addAudioInput_queued()

        switch mode {
        case .photo: try addPhotoOutput_queued()
        case .video: try addVideoOutput_queued()
        }

        NotificationCenter.default
            .publisher(for: .AVCaptureInputPortFormatDescriptionDidChange)
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.inputPortFormatDescriptionChanged_queued()
            }
            .store(in: &sessionSubscriptions)

        NotificationCenter.default
            .publisher(for: .AVCaptureSessionWasInterrupted)
            .receive(on: queue)
            .sink { [weak self] note in
                self?.sessionInterruptionBegan_queued(notification: note)
            }
            .store(in: &sessionSubscriptions)

        NotificationCenter.default
            .publisher(for: .AVCaptureSessionInterruptionEnded)
            .receive(on: queue)
            .sink { [weak self] _ in self?.sessionInterruptionEnded_queued() }
            .store(in: &sessionSubscriptions)
    }

    /// - throws: ConfigurationError
    private func addVideoInput_queued(videoDevice: AVCaptureDevice) throws {
        assert(queue.isCurrent)

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            throw ConfigurationError.unableToAddVideoInput(error)
        }

        guard session.canAddInput(videoInput) else {
            throw ConfigurationError.unableToAddVideoInput(nil)
        }

        session.addInput(videoInput)
        currentCamera = videoDevice
        currentInput = videoInput
        bodyPosition = videoDevice.position.bodyPosition

        NotificationCenter.default
            .publisher(for: .AVCaptureDeviceSubjectAreaDidChange, object: videoDevice)
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.subjectAreaDidChange_queued()
            }
            .store(in: &currentCameraSubscriptions)

        switch (videoInput.device.isFlashAvailable, options.preferredInitialFlashMode, flash) {
        case (true, .on, nil),
             (true, _, .on):
            flash = .on
        case (true, .off, nil),
             (true, _, .off):
            flash = .off
        case (true, .auto, nil),
             (true, _, .auto):
            flash = .auto
        case (false, _, _):
            flash = nil
        }
    }

    /// - throws: ConfigurationError
    private func addAudioInput_queued() throws {

        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            throw ConfigurationError.noMicrophoneFound
        }

        let audioInput: AVCaptureDeviceInput

        do {
            audioInput = try AVCaptureDeviceInput(device: microphone)
        } catch {
            throw ConfigurationError.unableToAddAudioInput(error)
        }

        guard session.canAddInput(audioInput) else {
            throw ConfigurationError.unableToAddAudioInput(nil)
        }

        session.addInput(audioInput)
    }

    /// - throws: ConfigurationError
    private func addPhotoOutput_queued() throws {
        assert(queue.isCurrent)

        guard session.canAddOutput(photoOutput) else {
            throw ConfigurationError.unableToAddPhotoOutput(nil)
        }

        session.addOutput(photoOutput)

        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        photoOutput.maxPhotoQualityPrioritization = .quality

        switch (photoOutput.isLivePhotoCaptureSupported, options.autoEnableLivePhotosIfAvailable) {
        case (true, true):
            livePhotos = .on
            photoOutput.isLivePhotoCaptureEnabled = true
        case (true, false):
            livePhotos = .off
            photoOutput.isLivePhotoCaptureEnabled = false
        case (false, _):
            livePhotos = nil
            photoOutput.isLivePhotoCaptureEnabled = false
        }
    }

    /// - throws: ConfigurationError
    private func addVideoOutput_queued() throws {
        assert(queue.isCurrent)
        assertionFailure("Video recording is not yet supported.")
        throw ConfigurationError.unableToAddVideoInput(nil)
    }

    // MARK: - Private Methods (Photo Capture)

    private func capturePhoto_queued() {
        assert(queue.isCurrent)

        guard let camera = currentCamera else { return }

        let videoOrientation = interfaceOrientation.videoOrientation
        photoOutput.connection(with: .video)?.videoOrientation = videoOrientation

        let options = AVCapturePhotoSettings.Options(
            livePhotos: livePhotos,
            flash: flash,
            quality: .quality)

        let settings = AVCapturePhotoSettings(
            camera: camera,
            output: photoOutput,
            options: options)

        let item = PhotoCaptureItem(settings: settings)

        let processor = PhotoProcessor(
            settings: settings,
            userOrientation: videoOrientation,
            callbackQueue: queue,
            uponWillCapture: { [weak self] in
                self?.photoCaptureItems.append(item)
            }, uponLivePhotoCaptureStateChange: { [weak self] isRecording in
                self?.livePhotosInProgress += isRecording ? 1 : -1
            }, uponIndeterminateProcessingChange: { isProcessing in
                item.state = isProcessing ? .continuingIndeterminately : .finished
            }, completion: { [weak self] (processor, result) in
                guard let self = self else { return }
                switch result {
                case .success(let photo):
                    self.passthroughSubject.send(photo)
                case .failure(let error):
                    ObligatoryLoggingPun.error("Failed to capture photo: \(error)")
                }
                if item.state != .finished {
                    item.state = .finished
                }
                self.photoCaptureItems.removeFirstInstance(of: item)
                self.processors[processor.uniqueID] = nil
            })

        processors[processor.uniqueID] = processor
        photoOutput.capturePhoto(with: settings, delegate: processor)
    }

    // MARK: - Private Methods (Changing Cameras)

    private func toggleBetweenFrontAndBackCameras_queued() {
        assert(queue.isCurrent)
        let nextPosition = bodyPosition.opposite
        let preferredCamera: AVCaptureDevice? = {
            switch nextPosition {
            case .front: return frontCameraDiscovery.devices.first
            case .back: return backCameraDiscovery.devices.first
            }
        }()
        guard let nextCamera = preferredCamera else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        removeCurrentVideoInput_queued()

        do {
            try addVideoInput_queued(videoDevice: nextCamera)
        } catch {
            ObligatoryLoggingPun.error("Unable to toggle cameras: \(error)")
            bodyPosition = .back
        }
    }

    private func removeCurrentVideoInput_queued() {
        assert(queue.isCurrent)
        if let previousInput = currentInput {
            currentCameraSubscriptions.removeAll()
            session.removeInput(previousInput)
            currentInput = nil
            currentCamera = nil
        }
    }

    // MARK: - Private Methods (Focus)

    private func subjectAreaDidChange_queued() {
        assert(queue.isCurrent)
        self.currentCamera?.focusAndExpose(
            at: CGPoint(x: 0.5, y: 0.5),
            focus: .continuousAutoFocus,
            exposure: .continuousAutoExposure,
            monitorSubjectAreaChanges: false
        )
    }

    // MARK: - Private Methods (Format Changes)

    private func inputPortFormatDescriptionChanged_queued() {
        assert(queue.isCurrent)
        guard let format = currentInput?.ports.first?.formatDescription else { return }
        dimensions = CMVideoFormatDescriptionGetDimensions(format)
    }

    // MARK: - Private Methods (Session Interruptions)

    private func sessionInterruptionBegan_queued(notification: Notification) {
        assert(queue.isCurrent)
        sessionInterruption = notification.sessionInterruption
    }

    private func sessionInterruptionEnded_queued() {
        assert(queue.isCurrent)
        sessionInterruption = nil
    }

}
