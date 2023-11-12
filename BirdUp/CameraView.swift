//
//  CameraView.swift
//  BirdUp
//
//  Created by Dillon Boardman on 11/11/2023.
//

import SwiftUI
import AVFoundation

class ViewController: UIViewController {
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let captureSession = AVCaptureSession()

    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var permission = false

    override func viewDidLoad() {
        checkPermission()
        sessionQueue.async { [unowned self] in
            guard permission else { return }
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                permission = true
            case .notDetermined:
                requestPermission()
            default:
                permission = false
            }
    }

    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permission = granted
            self.sessionQueue.resume()
        }
    }

    func setupCaptureSession() {
        guard let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }

        guard captureSession.canAddInput(deviceInput) else { return }
        captureSession.addInput(deviceInput)

        let screen = UIScreen.main.bounds.size
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screen.width, height: screen.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection!.videoRotationAngle = 90.0

        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in self!.view.layer.addSublayer(self!.previewLayer) }
    }
}

struct CameraViewController: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    func makeUIViewController(context: Context) -> UIViewController {
        return ViewController()
    }
}
