//
//  CameraCaptureHelper.swift
//  CoreImageHelpers
//
//  Created by Simon Gladman on 09/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
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
class CameraCaptureHelper: NSObject {
    var captureSession = AVCaptureSession()
    var cameraPosition: AVCaptureDevice.Position = AVCaptureDevice.Position.back
    var isRunning:Bool = false
    
    weak var delegate: CameraCaptureHelperDelegate?
    
    required init(cameraPosition: AVCaptureDevice.Position) {
        
        self.isRunning = false
        self.cameraPosition = cameraPosition
        super.init()

        initialiseCaptureSession()
    }
    
    
    public func start(){
        if !self.isRunning {
            self.isRunning = true
            captureSession.startRunning()
            log.verbose("Starting camera session")
        }
    }
    
    
    public func stop(){
        if self.isRunning {
            self.isRunning = false
            captureSession.stopRunning()
            log.verbose("Stopping camera session")
        }
    }
    
    public func switchCameraLocation(){
        stop()
        if self.cameraPosition == .front {
            self.cameraPosition = .back
        } else {
            self.cameraPosition = .front
        }
        initialiseCaptureSession()
        start()
    }
    
    
    
    fileprivate func initialiseCaptureSession() {
        
        let captureSession = AVCaptureSession()
        //captureSession.sessionPreset = AVCaptureSession.Preset.photo
        captureSession.sessionPreset = AVCaptureSession.Preset.inputPriority
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) {
            (granted: Bool) -> Void in
            guard granted else {
                log.error("access to hardware refused")
                return
            }
            log.verbose("Access granted")
        }
        
        let camera = self.getDevice(position: self.cameraPosition)

        do {
            let input = try AVCaptureDeviceInput(device: camera!)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                log.error("cannot add video input")
            }
        } catch {
            log.error("Unable to access camera")
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        //videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "phixer buffer delegate", attributes: []))
        let queue = DispatchQueue(label: "phixer buffer delegate")
        videoOutput.setSampleBufferDelegate(self, queue: queue)

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            captureSession.commitConfiguration()
        } else {
            log.error("cannot add video output capture")
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

}



extension CameraCaptureHelper: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            log.error("NIL pixel buffer returned")
            return
        }
        
        DispatchQueue.main.async {
            log.verbose("new camera image")
            self.delegate?.newCameraImage(self, image: CIImage(cvPixelBuffer: pixelBuffer))
        }
        
    }
}

protocol CameraCaptureHelperDelegate: class {
    func newCameraImage(_ cameraCaptureHelper: CameraCaptureHelper, image: CIImage)
}
