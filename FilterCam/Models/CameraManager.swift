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
        let devices = AVCaptureDevice.devices(withMediaType:AVMediaTypeVideo)
        for case let device as AVCaptureDevice in devices! {
            //TOFIX: check front or back
            //if (device.position == cameraLocation.captureDevicePosition()) {
                if (device.position == .back) {
                return device
            }
        }
        // if not found, return default device
        return AVCaptureDevice.defaultDevice(withMediaType:AVMediaTypeVideo)
    }
    
    open static func setCamera(_ camera: Camera, location: PhysicalCameraLocation){
        selectedCamera = camera
        cameraLocation = location
        cameraDevice = getDevice()
    }
    
    open static func getCamera() -> Camera? {
        
        if (selectedCamera==nil){
            do {
                selectedCamera = try Camera(sessionPreset:AVCaptureSessionPresetPhoto, location:cameraLocation)
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
            selectedCamera = getCamera()
            log.info(["Changed Camera location to:", location])
        }
        
    }
    
    open static func getCameraLocation() -> PhysicalCameraLocation {
        return cameraLocation
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
