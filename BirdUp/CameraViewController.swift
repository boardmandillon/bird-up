//
//  CameraViewController.swift
//  BirdUp
//
//  Created by Dillon Boardman on 11/11/2023.
//

import Vision
import SwiftUI
import AVFoundation

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let videoRotation = CGFloat(90)
    private let captureSession = AVCaptureSession()

    private var permission = false
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    private lazy var boundingBoxFaces: [CAShapeLayer] = []

    override func viewDidLoad() {
        checkPermission()
        sessionQueue.async { [unowned self] in
            guard permission else { return }
            self.setupCaptureInputSession()
            self.setupCaptureOutputSession()
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
            permission = granted
            sessionQueue.resume()
        }
    }

    func setupCaptureInputSession() {
        guard let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }

        guard captureSession.canAddInput(deviceInput) else { return }
        captureSession.addInput(deviceInput)

        let screen = UIScreen.main.bounds.size
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screen.width, height: screen.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoRotationAngle = videoRotation

        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in self!.view.layer.addSublayer(self!.previewLayer) }
    }

    func setupCaptureOutputSession() {
        let captureVideoDataOutput = AVCaptureVideoDataOutput()
        captureVideoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        captureSession.addOutput(captureVideoDataOutput)
        captureVideoDataOutput.connection(with: AVMediaType.video)?.videoRotationAngle = videoRotation
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectFace(in: frame)
    }

    private func detectFace(in image: CVPixelBuffer) {
        let faceDetection = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, _) in
            DispatchQueue.main.async {
                self.boundingBoxFaces.forEach({ drawing in drawing.removeFromSuperlayer() })
                if let results = request.results as? [VNFaceObservation] { self.handleFaceDetectionResults(results) }
            }
        })

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetection])
    }

    private func handleFaceDetectionResults(_ observed: [VNFaceObservation]) {
        let boundingBoxFaces: [CAShapeLayer] = observed.flatMap({ (face: VNFaceObservation) -> [CAShapeLayer] in
            let boundingBoxOnScreen = previewLayer.layerRectConverted(fromMetadataOutputRect: face.boundingBox)
            let boundingBoxPath = CGPath(rect: boundingBoxOnScreen, transform: nil)
            let boundingBoxShape = CAShapeLayer()
            boundingBoxShape.path = boundingBoxPath
            boundingBoxShape.fillColor = UIColor.clear.cgColor
            boundingBoxShape.strokeColor = UIColor.systemYellow.cgColor
            boundingBoxShape.lineJoin = .bevel
            boundingBoxShape.lineWidth = 1.33
            return [boundingBoxShape]
        })

        boundingBoxFaces.forEach({ boundingBoxFace in view.layer.addSublayer(boundingBoxFace) })
        self.boundingBoxFaces = boundingBoxFaces
    }
}

struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    func makeUIViewController(context: Context) -> UIViewController {
        return CameraViewController()
    }
}
