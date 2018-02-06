import UIKit
import AVFoundation

protocol VideoFeedDelegate: class {
	func frame(image: CGImage)
	func captured(image: UIImage)
}

class VideoFeed: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
	
	private let position = AVCaptureDevice.Position.back
	private let quality = AVCaptureSession.Preset.photo
	
	private var permissionGranted = false
	private let sessionQueue = DispatchQueue(label: "session queue")
	private let captureSession = AVCaptureSession()
	private let context = CIContext()
	
	var previewLayer: AVCaptureVideoPreviewLayer!
	var cameraOutput:AVCapturePhotoOutput!

	weak var delegate: VideoFeedDelegate?
	
	override init() {
		super.init()
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		checkPermission()
		sessionQueue.async { [unowned self] in
			self.configureSession()
			self.captureSession.startRunning()
		}
	}
	
	// MARK: AVSession configuration
	private func checkPermission() {
		switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
		case .authorized:
			permissionGranted = true
		case .notDetermined:
			requestPermission()
		default:
			permissionGranted = false
		}
	}
	
	private func requestPermission() {
		sessionQueue.suspend()
		AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
			self.permissionGranted = granted
			self.sessionQueue.resume()
		}
	}
	
	private func configureSession() {
		guard permissionGranted else { return }
		captureSession.sessionPreset = quality
		guard let captureDevice = selectCaptureDevice() else { return }
		guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
		guard captureSession.canAddInput(captureDeviceInput) else { return }
		captureSession.addInput(captureDeviceInput)

		cameraOutput = AVCapturePhotoOutput()
		guard captureSession.canAddOutput(cameraOutput) else { return }
		captureSession.addOutput(cameraOutput)

		let videoOutput = AVCaptureVideoDataOutput()
		videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
		guard captureSession.canAddOutput(videoOutput) else { return }
		captureSession.addOutput(videoOutput)
		guard let connection = videoOutput.connection(with: AVFoundation.AVMediaType.video) else { return }
		guard connection.isVideoOrientationSupported else { return }
		guard connection.isVideoMirroringSupported else { return }
		connection.videoOrientation = .portrait
		connection.isVideoMirrored = position == .front
	}
	
	private func selectCaptureDevice() -> AVCaptureDevice? {
		let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
		return deviceDescoverySession.devices.filter {
			($0 as AnyObject).hasMediaType(AVMediaType.video) && ($0 as AnyObject).position == AVCaptureDevice.Position.back
		}.first
	}
	
	func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
		
		if let error = error { print("error: \(error.localizedDescription)") }
		
		if  let sampleBuffer = photoSampleBuffer,
			let previewBuffer = previewPhotoSampleBuffer,
			let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
			let dataProvider = CGDataProvider(data: dataImage as CFData)
			let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
			let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: .right)
			self.delegate?.captured(image: image)
		} else {
			print("error")
		}
	}

	
	// MARK: Sample buffer to UIImage conversion
	private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
//		let ciImage = CIImage(cvImageBuffer: imageBuffer)
		let ciImage = CIImage(cvPixelBuffer: imageBuffer)
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
		return UIImage(cgImage: cgImage)
	}
	private func cgImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
//		let ciImage = CIImage(cvImageBuffer: imageBuffer)
		let ciImage = CIImage(cvPixelBuffer: imageBuffer)
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
		return cgImage
	}

	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//		guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
		guard let cgImage = cgImageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
		DispatchQueue.main.async { [unowned self] in
			self.delegate?.frame(image: cgImage)
		}
	}
	
	func takePhoto(){
		let settings = AVCapturePhotoSettings()
		let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
		let previewFormat = [
			kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
			kCVPixelBufferWidthKey as String: 160,
			kCVPixelBufferHeightKey as String: 160
		]
		settings.previewPhotoFormat = previewFormat
		self.cameraOutput.capturePhoto(with: settings, delegate: self)
	}
	
}
