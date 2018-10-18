//
//  CameraCaptureHelper.swift
//
//
//  Based on CoreImageHelpers git repo by Simon Gladman
// Also reference Aple docs at: https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/setting_up_a_capture_session
//

import AVFoundation
import CoreMedia
import CoreImage
import UIKit

/// `CameraCaptureHelper` wraps up all the code required to access an iOS device's
/// camera images and convert to a series of `CIImage` images.
///
/// The helper's delegate, `CameraCaptureHelperDelegate` receives notification of
/// a new image in the main thread via `newCameraImage()`.
@available(iOS 11.0, *)
class CameraCaptureHelper: NSObject {
    // there should only be one instance of the following vars, hence they are made static
    fileprivate static var captureSession:AVCaptureSession? = nil
    private static var requestQueue: DispatchQueue = DispatchQueue(label: "CameraCaptureHelper")
    
    // the following are static becuase they affect all instances
    fileprivate static var camera:AVCaptureDevice? = nil
    fileprivate static var deviceInput:AVCaptureDeviceInput? = nil
    fileprivate static var cameraPosition: AVCaptureDevice.Position = AVCaptureDevice.Position.back
    fileprivate static var isRunning:Bool = false
    
    // the following are instance vars, i.e. unique to this particular object, not shared
    private static var videoOutput:AVCaptureVideoDataOutput? = nil
    private static var photoOutput:AVCapturePhotoOutput? = nil
    private static var bufferQueue: DispatchQueue? = nil

    
    //weak var delegate: CameraCaptureHelperDelegate?
    
    private static var delegates:MulticastDelegate<CameraCaptureHelperDelegate> = MulticastDelegate<CameraCaptureHelperDelegate>()
    
    static var frameCount:Int = 0
    static var dropCount:Int = 0
    
    private var tag:String = ""

    
    required init(cameraPosition: AVCaptureDevice.Position) {
        
        super.init()
        log.verbose("init(position)")
        CameraCaptureHelper.cameraPosition = cameraPosition
        doInit()
    }
    
    
    // this version can be used by code that wants to access the video/photo data, but not set the position
    override init (){
        super.init()
        log.verbose("init()")
        doInit()
        // don't overwrite any static vars
 
   }
    
    deinit{
        self.deregister()
    }
    
    private func doInit(){
        if CameraCaptureHelper.captureSession == nil {
            CameraCaptureHelper.isRunning = false
            CameraCaptureHelper.videoOutput = nil
            CameraCaptureHelper.photoOutput = nil
            CameraCaptureHelper.bufferQueue = nil
            //CameraCaptureHelper.requestQueue.async(execute: {
            DispatchQueue.main.async(execute: {
                self.initialiseCaptureSession()
            })
      }
    }
    
    public func register(delegate:CameraCaptureHelperDelegate, key:String){
        CameraCaptureHelper.delegates.add(key:key, delegate: delegate)
        self.tag = key
    }
    
    public func deregister(key:String=""){
        let k = (key.isEmpty) ? self.tag : key

        CameraCaptureHelper.delegates.remove(key:k)
        if CameraCaptureHelper.delegates.count() <= 0 {
            stop()
            CameraCaptureHelper.captureSession = nil
            CameraCaptureHelper.isRunning = false
            CameraCaptureHelper.videoOutput = nil
            CameraCaptureHelper.photoOutput = nil
        }
    }

    public func start(){
        //CameraCaptureHelper.requestQueue.async(execute: {
        DispatchQueue.main.async(execute: {
            if !CameraCaptureHelper.isRunning {
                CameraCaptureHelper.isRunning = true
                self.initialiseCaptureSession()
                CameraCaptureHelper.captureSession?.startRunning()
                log.verbose("Starting camera session")
            }
        })
    }
    
    
    public func stop(){
        //CameraCaptureHelper.requestQueue.async(execute: {
        DispatchQueue.main.async(execute: {
            if CameraCaptureHelper.isRunning {
                CameraCaptureHelper.isRunning = false
                CameraCaptureHelper.captureSession?.stopRunning()
                log.verbose("Stopping camera session")
            }
        })
    }
    
    public func switchCameraLocation(){
        //CameraCaptureHelper.requestQueue.async(execute: {
        DispatchQueue.main.async(execute: {
            self.stop()
            //TODO: need to change devices in the capture session
            if CameraCaptureHelper.cameraPosition == .front {
                CameraCaptureHelper.cameraPosition = .back
            } else {
                CameraCaptureHelper.cameraPosition = .front
            }
            self.initialiseCaptureSession()
            self.start()
        })
    }
    
    
    
    fileprivate func initialiseCaptureSession() {
        
        if CameraCaptureHelper.captureSession == nil {
            CameraCaptureHelper.captureSession = AVCaptureSession()
            log.verbose("Setting up capture Session")
            CameraCaptureHelper.captureSession?.beginConfiguration()
            
            //captureSession?.sessionPreset = AVCaptureSession?.Preset.photo
            //CameraCaptureHelper.captureSession?.sessionPreset = AVCaptureSession.Preset.inputPriority
            //CameraCaptureHelper.captureSession?.sessionPreset = AVCaptureSession.Preset.medium
            CameraCaptureHelper.captureSession?.sessionPreset = AVCaptureSession.Preset.photo
            
            AVCaptureDevice.requestAccess(for: AVMediaType.video) {
                (granted: Bool) -> Void in
                guard granted else {
                    log.error("access to hardware refused")
                    return
                }
                log.verbose("Access granted")
            }
            
            CameraCaptureHelper.camera = getDevice(position: CameraCaptureHelper.cameraPosition)

            do {
                CameraCaptureHelper.deviceInput = try AVCaptureDeviceInput(device: CameraCaptureHelper.camera!)
                
                if (CameraCaptureHelper.captureSession?.canAddInput(CameraCaptureHelper.deviceInput!))! {
                    CameraCaptureHelper.captureSession?.addInput(CameraCaptureHelper.deviceInput!)
                } else {
                    log.error("cannot add device to session")
                }
            } catch {
                log.error("Unable to access camera")
                CameraCaptureHelper.captureSession?.commitConfiguration()
               return
            }
            CameraCaptureHelper.captureSession?.commitConfiguration()
        } else {
            log.debug("Capture session already active")
        }

        // add the video stream
        if (CameraCaptureHelper.videoOutput == nil) {
            CameraCaptureHelper.videoOutput = AVCaptureVideoDataOutput()
            log.verbose("Setting up video output")
            CameraCaptureHelper.captureSession?.beginConfiguration()
            //CameraCaptureHelper.videoOutput?.alwaysDiscardsLateVideoFrames = true
            CameraCaptureHelper.videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
            //videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "phixer buffer delegate", attributes: []))
            if (CameraCaptureHelper.bufferQueue == nil) { CameraCaptureHelper.bufferQueue = DispatchQueue(label: "video buffer delegate") }
            CameraCaptureHelper.videoOutput?.setSampleBufferDelegate(self, queue: CameraCaptureHelper.bufferQueue)
            
            let check = CameraCaptureHelper.captureSession?.canAddOutput(CameraCaptureHelper.videoOutput!)
            if (check!) {
                CameraCaptureHelper.captureSession?.addOutput(CameraCaptureHelper.videoOutput!)
            } else {
                log.error("cannot add video output capture")
            }
            CameraCaptureHelper.captureSession?.commitConfiguration()
        } else {
            log.debug("Video already set up")
        }
        
        // add the photo capture logic
        if (CameraCaptureHelper.photoOutput == nil) {
            CameraCaptureHelper.photoOutput = AVCapturePhotoOutput()
            log.verbose("Setting up photo output")
            // Get an instance of ACCapturePhotoOutput class
            CameraCaptureHelper.photoOutput?.isHighResolutionCaptureEnabled = true

            // Set the output on the capture session
            let check = CameraCaptureHelper.captureSession?.canAddOutput(CameraCaptureHelper.photoOutput!)
            if (check!) {
                CameraCaptureHelper.captureSession?.addOutput(CameraCaptureHelper.photoOutput!)
            } else {
                log.error("cannot add photo output capture")
            }
            
            CameraCaptureHelper.captureSession?.commitConfiguration()
        } else {
            log.debug("Photo already set up")
       }
    }
    
    
    
    //Get the device (Front or Back)
    private func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
      
        if let camera = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                           mediaType: AVMediaType.video,
                                                           position: position).devices.first{
            log.verbose("Using device: \"\(camera.localizedName)\" for position:\(position)")
            return camera
        } else {
            return AVCaptureDevice.default(for: .video)
        }
    }

    
    public func takePhoto(){
        guard CameraCaptureHelper.photoOutput != nil else {
            log.error("Photo capture not set up...")
            return
        }
        guard (CameraCaptureHelper.isRunning) else {
            log.warning("Camera feed is not active. Ignoring")
            return
        }
        // Set up photo parameters
        let photoSettings = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        
        // request the photo. Completion comes through the photoOutput() extension
        CameraCaptureHelper.photoOutput?.capturePhoto(with: photoSettings, delegate: self)
    }

}


////////////////////////
// Extensions
/////////////////////////


extension CameraCaptureHelper: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {


        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            log.error("NIL pixel buffer returned")
            return
        }
        DispatchQueue.main.async {
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
            //log.verbose("new camera image")
            //let n = CameraCaptureHelper.delegates.count()
            //log.verbose("calling \(n) delegates..")
            CameraCaptureHelper.delegates.invoke {
                $0.newCameraImage(self, image: CIImage(cvPixelBuffer: pixelBuffer))
            }
            
            //CameraCaptureHelper.frameCount = (CameraCaptureHelper.frameCount+1)%100
            //if CameraCaptureHelper.frameCount == 0 {
            //    log.verbose("sent 100 images")
            //}
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        CameraCaptureHelper.dropCount = (CameraCaptureHelper.dropCount+1)%100
        if CameraCaptureHelper.dropCount == 0 {
            log.verbose("dropped 100 frames")
        }
    }
}



@available(iOS 11.0, *)
extension CameraCaptureHelper: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?){
        // Make sure we get some photo sample buffer
        guard error == nil else {
                log.error("Error capturing photo: \(String(describing: error))")
                return
        }
        
        // Check if the pixel buffer could be converted to image data
        guard let imageData = photo.fileDataRepresentation() else {
            log.error("Failed to convert pixel buffer")
            return
        }
        
        /***
        // Check if UIImage could be initialized with image data
        guard let capturedImage = UIImage.init(data: imageData , scale: 1.0) else {
            log.error("Failed to convert image data to UIImage")
            return
        }
        
        // Get original image width/height
        let imgWidth = capturedImage.size.width
        let imgHeight = capturedImage.size.height
        // Get origin of cropped image
        let imgOrigin = CGPoint(x: (imgWidth - imgHeight)/2, y: (imgHeight - imgHeight)/2)
        // Get size of cropped iamge
        let imgSize = CGSize(width: imgHeight, height: imgHeight)
        
        // Check if image could be cropped successfully
        guard let imageRef = capturedImage.cgImage?.cropping(to: CGRect(origin: imgOrigin, size: imgSize)) else {
            print("Failed to crop image")
            return
        }
        ***/
        
        let image = UIImage(data: imageData)
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        
        // call delegate to let it know that photo has been saved
       // delegate?.photoTaken()
        CameraCaptureHelper.delegates.invoke {
            $0.photoTaken()
        }


    }
}


////////////////////////
// Protocol required to use this class
////////////////////////

@available(iOS 11.0, *)
protocol CameraCaptureHelperDelegate: class {
    func newCameraImage(_ cameraCaptureHelper: CameraCaptureHelper, image: CIImage)
    func photoTaken()
}
