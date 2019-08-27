//
//  InputSource.swift
//  phixer
//
//  Created by Philip Price on 12/6/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage
import UIKit


// Class that manages the various input sources (sample file, photo being edited, camera)


protocol InputSourceDelegate: class {
    func inputChanged(image: CIImage?)
    func photoTaken()
}


// enum describing the input source for previewing filters
public enum InputSourceType {
    case camera
    case sample
    case edit
}

// variables that hold the current state
fileprivate var camera: CameraCaptureHelper? = nil
fileprivate var currSource: InputSourceType = .sample
fileprivate var currInput:CIImage? = nil

// list of delegates for callbacks
fileprivate var delegates:MulticastDelegate<InputSourceDelegate> = MulticastDelegate<InputSourceDelegate>()

// class that handles the camera callback
fileprivate class CameraDelegate:CameraCaptureHelperDelegate {
    func newCameraImage(_ cameraCaptureHelper: CameraCaptureHelper, image: CIImage) {
        if currSource == .camera {
            currInput = image
            DispatchQueue.main.async(execute: { () -> Void in
                delegates.invoke {
                    $0.inputChanged(image: image)
                }
            })
        }
    }
    
    func photoTaken(){
        delegates.invoke {
            $0.photoTaken()
        }
    }
}

// instance of the camera callback class
fileprivate var cameraDelegate:CameraDelegate = CameraDelegate()




class InputSource {

    
    //////////////////////////////////
    // Accessors
    //////////////////////////////////
    
    // list of subscribers for callbacks
    fileprivate static var delegates:MulticastDelegate<InputSourceDelegate> = MulticastDelegate<InputSourceDelegate>()
    
    // make initialiser private to prevent instantiation
    private init(){}
    
    
    // register for callbacks
    public static func register(_ delegate:InputSourceDelegate, key:String=""){
        let k = (key.isEmpty) ? #file : key
        delegates.add(key:k, delegate: delegate)
    }
    
    // deregister callbacks
    public static func deregister(key:String=""){
        let k = (key.isEmpty) ? #file : key
        delegates.remove(key:k)
    }

    public static func getCurrent() -> InputSourceType {
        return currSource
    }

    
    // set the current input type
    public static func setCurrent(source: InputSourceType){
        currSource = source
        switch (currSource){
        case .camera:
            initCamera()
        case .sample:
            camera?.stop()
            currInput = ImageManager.getCurrentSampleInput()
        case .edit:
            camera?.stop()
            currInput = ImageManager.getCurrentEditImage()
        }
    }
    
    // get the name associated with the current input
    public static func getCurrentName() -> String {
        switch (currSource){
        case .camera:
            return "camera"
        case .sample:
            return ImageManager.getCurrentSampleImageName()
        case .edit:
            return ImageManager.getCurrentEditImageName()
        }
    }
    
    // get the current input image
    public static func getCurrentImage()->CIImage?{
        switch (currSource){
        case .camera:
            return currInput // updated in callback
        case .sample:
            currInput = ImageManager.getCurrentSampleImage()
        case .edit:
            currInput = ImageManager.getCurrentEditImage()
        }
        return currInput
    }
    
    // get the current input image of specified size
    public static func getCurrentImage(size:CGSize)->CIImage?{
        switch (currSource){
        case .camera:
            return currInput // updated in callback
        case .sample:
            currInput = ImageManager.getCurrentSampleImage(size:size)
        case .edit:
            currInput = ImageManager.getCurrentEditImage(size: size)
        }
        return currInput
    }

    
    // get the size of the current image
    public static func getSize() -> CGSize {
        var size:CGSize = CGSize.zero
        size = UIScreen.main.bounds.size // default to screen size (what else?)
        if currInput != nil {
            if currInput?.extent.size != nil {
                size = (currInput?.extent.size)!
            }
        }
        return size
    }
    
    // get the extent of the current image
    public static func getExtent() -> CGRect {
        var extent:CGRect = CGRect.zero
        extent = UIScreen.main.bounds // default to screen size (what else?)
        if currInput != nil {
            if currInput?.extent != nil {
                extent = (currInput?.extent)!
            }
        }
        return extent
    }

    
    // returns the w:h aspect ratio
    public static func getAspectRatio() -> CGFloat{
        var ratio: CGFloat = 1.0
        
        // calculate the aspect ratio as a 1:N (w:h) floating point number
        if ((currInput?.extent.size.height)!>CGFloat(0.0)){
            ratio = (currInput?.extent.size.width)! / (currInput?.extent.size.height)!
        }
        return ratio
    }

    // returns the current CG Orientation
    public static func getOrientation() -> CGImagePropertyOrientation {
        return ImageManager.getEditImageOrientation()
    }
    
    
    /***
    // register for callbacks
    public func register(delegate:InputSourceDelegate, key:String){
        delegates.add(key:key, delegate: delegate)
    }
    
    
    // deregister callbacks
    public func deregister(key:String=""){
        let k = (key.isEmpty) ? #file : key
        
        delegates.remove(key:k)
        if delegates.count() <= 0 {
            camera?.stop()
        }
    }
     ***/
    
    //////////////////////////////////
    // Camera-related
    //////////////////////////////////
    
    // start the camera
    public static func startCamera(){
        if currSource == .camera {
            initCamera()
        }
    }
    
    // stop the camera
    public static func stopCamera(){
        if currSource == .camera {
            camera?.stop()
        }
    }
    
    
    // suspend all Camera-related processing
    public static func suspend(){
        camera?.deregister()
    }
    
    private static func initCamera(){
        if camera == nil {
            camera = CameraCaptureHelper()
            camera?.register(delegate:cameraDelegate, key:#file)
        }
        if currSource == .camera {
            camera?.start()
        }
    }
    
}



