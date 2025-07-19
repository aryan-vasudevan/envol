import SwiftUI
import AVFoundation

class CameraManager: NSObject, ObservableObject {
    @Published var isCameraAvailable = false
    @Published var permissionGranted = false
    
    private var captureSession: AVCaptureSession?
    private var videoOutput = AVCaptureVideoDataOutput()
    private var photoOutput = AVCapturePhotoOutput()
    
    override init() {
        super.init()
        // Only check camera permission if not in preview
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // In preview mode, just set basic state
            isCameraAvailable = false
            permissionGranted = false
        } else {
            checkCameraPermission()
        }
        #else
        checkCameraPermission()
        #endif
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            isCameraAvailable = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    self?.isCameraAvailable = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            permissionGranted = false
            isCameraAvailable = false
        @unknown default:
            permissionGranted = false
            isCameraAvailable = false
        }
    }
    
    private func setupCamera() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return // Skip camera setup in preview
        }
        #endif
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to access back camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession?.canAddInput(input) == true {
                captureSession?.addInput(input)
            }
            
            if captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: completion))
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
}

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil)
            return
        }
        
        completion(image)
    }
} 