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
    var cameraPosition: AVCaptureDevice.Position
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
        }
    }
    
    
    public func stop(){
        if self.isRunning {
            self.isRunning = false
            captureSession.stopRunning()
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
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        //let camera = ( AVCaptureDevice.default(for: AVMediaType.video))
        let camera = self.getDevice(position: self.cameraPosition)

        do {
            let input = try AVCaptureDeviceInput(device: camera!)
            
            captureSession.addInput(input)
        } catch {
            log.error("Unable to access camera")
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        

    }
    
    //Get the device (Front or Back)
    private func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [], mediaType: .video, position: position).devices
        print("devices:\(devices)")
        for device in devices where device.position == position {
            return device
        }
        return AVCaptureDevice.default(for: .video)
    }

}



extension CameraCaptureHelper: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        DispatchQueue.main.async {
                self.delegate?.newCameraImage(self, image: CIImage(cvPixelBuffer: pixelBuffer))
        }
        
    }
}

protocol CameraCaptureHelperDelegate: class {
    func newCameraImage(_ cameraCaptureHelper: CameraCaptureHelper, image: CIImage)
}
