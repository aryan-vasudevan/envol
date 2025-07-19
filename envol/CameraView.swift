import SwiftUI
import AVFoundation
import UIKit

struct CameraView: UIViewControllerRepresentable {
    let cameraManager: CameraManager
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.cameraManager = cameraManager
        controller.onImageCaptured = onImageCaptured
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var cameraManager: CameraManager!
    var onImageCaptured: ((UIImage) -> Void)!
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Camera preview
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        // Capture button
        let captureButton = UIButton(type: .system)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 5
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        view.addSubview(captureButton)
        
        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Instructions label
        let instructionsLabel = UILabel()
        instructionsLabel.text = "Tap to capture photo"
        instructionsLabel.textColor = .white
        instructionsLabel.textAlignment = .center
        instructionsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.addSubview(instructionsLabel)
        
        // Layout constraints
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            instructionsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionsLabel.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -20)
        ])
    }
    
    private func setupCamera() {
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
            
            let photoOutput = AVCapturePhotoOutput()
            if captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            }
            
            previewLayer?.session = captureSession
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    @objc private func captureButtonTapped() {
        guard let captureSession = captureSession else { return }
        
        let photoOutput = captureSession.outputs.first as? AVCapturePhotoOutput
        let settings = AVCapturePhotoSettings()
        
        photoOutput?.capturePhoto(with: settings, delegate: PhotoCaptureDelegate { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    self?.onImageCaptured(image)
                }
            }
        })
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
} 