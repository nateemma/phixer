//
//  InputSource.swift
//  phixer
//
//  Created by Philip Price on 12/6/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage


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
    
    
    // get the current input image
    public static func getCurrentImage()->CIImage?{
        switch (currSource){
        case .camera:
            return currInput // updated in callback
        case .sample:
            currInput = ImageManager.getCurrentSampleInput()
        case .edit:
            currInput = ImageManager.getCurrentEditImage()
        }
        return currInput
    }
    
    
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



