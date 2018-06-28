//
//  CameraManager.swift
//  FilterCam
//
//  Created by Philip Price on 9/25/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import GPUImage


// Class that holds data relating to the curent camera settings
class CameraManager {
    
    
    let captureSession = AVCaptureSession()
    
    // vars related to the selected camera/video device
    // Note: I am using the funcs provided by GPUImage to maintain compatibility with the rendering code
    fileprivate static var selectedCamera : Camera? = nil
    fileprivate static var cameraLocation: PhysicalCameraLocation = .backFacing
    fileprivate static var cameraDevice: AVCaptureDevice? = nil
    fileprivate static var cameraRunning:Bool = false
    
    // ISO
    fileprivate static var currISO: Float = 0.0
    fileprivate static var selectedISO: CameraISO = CameraISO.iso_auto
    fileprivate static var currISOString: String = "?"
    
    // Speed
    fileprivate static var currSpeed: Float = 0.0
    fileprivate static var selectedSpeed: CameraSpeed = CameraSpeed.speed_auto
    fileprivate static var currSpeedString: String = "?"
    
    // White Balance
    
    // Flash
    
    // Exposure Compensation
    
    // Focus
    
    // Exposure lock
    
    
    
    //MARK: - Camera Selection
    
    fileprivate static func getDevice() -> AVCaptureDevice? {
        
        // look for the camera device in the selected position (front/back)
        let devices = AVCaptureDevice.devices(for:AVMediaType.video)
        for case let device as AVCaptureDevice in devices {
            if (device.position == translatePosition(cameraLocation)) {
                //log.debug("Found device: \(cameraLocation)")
                return device
            }
        }
        // if not found, return default device
        return AVCaptureDevice.default(for:AVMediaType.video)
    }
    
    static func translatePosition(_ location:PhysicalCameraLocation)->AVCaptureDevice.Position {
        switch location {
        case .backFacing: return .back
        case .frontFacing: return .front
        }
    }
    
    open static func setCamera(_ camera: Camera, location: PhysicalCameraLocation){
        selectedCamera = camera
        cameraLocation = location
        cameraDevice = getDevice()
    }
    
    open static func getCamera() -> Camera? {
        
        if (selectedCamera==nil){
            do {
                //log.debug("Allocating Camera")
                selectedCamera = try Camera(sessionPreset:AVCaptureSession.Preset.photo.rawValue, location:cameraLocation)
                setCamera(selectedCamera!, location:cameraLocation)
                //selectedCamera!.runBenchmark = true
            } catch {
                selectedCamera = nil
                log.error("Couldn't initialize camera. Error: \(error)")
            }
        }
        return selectedCamera
    }
    
    
    open static func setCameraLocation(_ location: PhysicalCameraLocation) {
        if (cameraLocation != location){
            cameraLocation = location
            stopCapture()
            selectedCamera = nil // force reallocation of Camera device (HACK)
            selectedCamera = getCamera()
            log.info("Changed Camera location to:\(location)")
        }
        
    }
    
    open static func startCapture(){
        selectedCamera?.startCapture()
        cameraRunning = true
        //selectedCamera?.removeAllTargets()
    }
    
    open static func stopCapture(){
        if (cameraRunning){
            cameraRunning = false
            selectedCamera?.stopCapture()
            selectedCamera?.removeAllTargets()
        }
    }
    
    
    open static func switchCameraLocation() {
        if (cameraLocation == .frontFacing){
            setCameraLocation(.backFacing)
        } else {
            setCameraLocation(.frontFacing)
        }
        selectedCamera = getCamera()
        //log.info("Changed Camera location to:\(cameraLocation)")
    }
    
    open static func getCameraLocation() -> PhysicalCameraLocation {
        return cameraLocation
    }
    
    
    // returns the current screen resolution (differs by device type)
    open static func getCaptureResolution() -> CGSize {
        // Define default resolution
        var resolution = CGSize(width: 0, height: 0)
        
        // Set if video portrait orientation
        let portraitOrientation = (UIScreen.main.bounds.height > UIScreen.main.bounds.width)
        
        // Get video dimensions
        if (cameraDevice == nil){
            log.warning("Camera not allocated")
            selectedCamera = getCamera()
        }
        
        if let formatDescription = CameraManager.cameraDevice?.activeFormat.formatDescription {
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            resolution = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
        } else {
            log.warning("formatDescription error. Setting resolution to screen default")
            resolution = CGSize(width: CGFloat(UIScreen.main.bounds.width), height: CGFloat(UIScreen.main.bounds.height))
        }
        
        if (!portraitOrientation) {
            resolution = CGSize(width: resolution.height, height: resolution.width)
        }
        
        // Return resolution
        return resolution
    }
    
    
    //MARK: - ISO
    
    // retrieve the current ISO setting
    open static func getCurrentISO() -> String {
        
        
        //if (selectedCamera == nil){ selectedCamera = findCameraDevice()}
        
        if let device = cameraDevice {
            do {
                try device.lockForConfiguration()
                
                currISO = device.iso
                print ("!!! getCurrentISO() raw ISO: \(currISO)")
                
            } catch let error1 as NSError {
                log.error ("!!! getCurrentISO() Error: \(error1.localizedDescription)")
            }
            
            device.unlockForConfiguration()
        }
        
        currISOString = String(format: "%.0f", currISO)
        
        return currISOString
    }
    
    
    //MARK: - Speed
    
    // retrieve the current Speed setting
    open static func getCurrentSpeed() -> String {
        
        //if (selectedCamera == nil){ selectedCamera = findCameraDevice()}
        
        if let device = cameraDevice {
            do {
                try device.lockForConfiguration()
                
                let time = device.exposureDuration
                currSpeed = Float(time.value) / Float(time.timescale)
                
                // convert to seconds or a fraction
                if(currSpeed<1.0){
                    // can get some funny values, so try and reduce the fraction
                    //let x: Fraction = Fraction(time.value) / Fraction(Int64(time.timescale))
                    //log.verbose (["Speed Fraction: ", x])
                    //currSpeedString = String(format: "%d/%d", time.value, time.timescale)
                    
                    var n:Int = 0
                    var d:Int = 0
                    (n,d) = ClosestFraction.find(currSpeed, maxDenominator: 1000) //TEST
                    
                    //currSpeedString = String(format: "\(x)") //TODO: deal with strange fractions (esp. 3rds)
                    currSpeedString = String(format: "\(n)/\(d)") //TODO: deal with strange fractions (esp. 3rds)
                } else {
                    currSpeedString = String(format: "%d", time.value)
                }
                log.verbose ("!!! getCurrentSpeed() Speed: \(currSpeedString) (v:\(time.value), t:\(time.timescale))")
                
            } catch let error1 as NSError {
                log.verbose ("!!! getCurrentSpeed() Error: \(error1.localizedDescription)")
            }
            
            device.unlockForConfiguration()
        }
        
        return currSpeedString
    }
    
    //MARK: - White Balance
    
    //MARK: - Flash
    
    //MARK: - Exposure Compensation
    
    //MARK: - Focus
    
    //MARK: - Exposure Lock
    
}
