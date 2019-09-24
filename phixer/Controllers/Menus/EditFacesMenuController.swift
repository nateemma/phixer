//
//  EditFacesMenuController.swift
//  phixer
//
//  Created by Philip Price on 12/17/18
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon




// This View Controller handles the menu and options for facial Adjustments

class EditFacesMenuController: EditBaseMenuController {
    
    var inputImage: CIImage? = nil
    var inputSize: CGSize = CGSize.zero
    var inputOrientation: CGImagePropertyOrientation = CGImagePropertyOrientation.up
    var faceList: [FacialFeatures] = []

    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        FaceDetection.reset()
    }
    
    
    //////////////////////////////////////////
    // MARK: - Override funcs for specifying items
    //////////////////////////////////////////
    
    
    // returns the text to display at the top of the window
    override func getTitle() -> String {
        return "Face Adjustments"
    }

    // returns the list of titles for each item
    override func getItemList() -> [Adornment] {
        return itemList
    }

    
    // Adornment list
    fileprivate var itemList: [Adornment] = [ Adornment(key: "lips",       text: "Lips",          icon: "ic_lips", view: nil, isHidden: false),
                                              Adornment(key: "skin",       text: "Skin",          icon: "ic_acne", view: nil, isHidden: false),
                                              Adornment(key: "teeth",      text: "Teeth",         icon: "ic_smile", view: nil, isHidden: false),
                                              Adornment(key: "eyes",       text: "Eyes",          icon: "ic_eye", view: nil, isHidden: false),
                                              Adornment(key: "eyebrows",   text: "Eyebrows",      icon: "ic_eyebrow", view: nil, isHidden: false),
                                              Adornment(key: "auto",       text: "Auto Adjust",   icon: "ic_magic", view: nil, isHidden: false) ]

    
    // handler for selected adornments:
    override func handleSelection(key:String){

        
        inputImage = EditManager.getPreviewImage()
        inputSize = EditManager.getImageSize()
        let orientation = EditManager.getEditImageOrientation()

        guard inputImage != nil else {
            log.error("NIL inputImage")
            return
        }
 
        // run face detection. Note that this relies on the ViewController restting face detection if the image changes. This is done to improve efficiency
        //FaceDetection.reset()
        if FaceDetection.count() <= 0 {
            FaceDetection.detectFaces(on: self.inputImage!, orientation: self.inputOrientation, completion: {} )
        }
        
        DispatchQueue.main.async {
            
            // Run face detection each time.
            // This is inefficient but simple. We could try to batch the change, but would need to detect first run and when image changes (TODO?)
            
            if FaceDetection.count() > 0 {
                self.faceList = FaceDetection.getFeatures()
                switch (key){
                case "lips": self.lipsHandler()
                case "skin": self.skinHandler()
                case "teeth": self.teethHandler()
                case "eyes": self.eyesHandler()
                case "eyebrows": self.eyebrowsHandler()
                case "auto": self.autoHandler()
                default:
                    log.error("Unknown key: \(key)")
                }
            } else {
                self.displayTimedMessage(title: "No Faces", text: "No faces were detected", time: 1.0)
            }
        }

    }

    //////////////////////////////////////////
    // MARK: - Handlers for the menu items
    //////////////////////////////////////////

    
    func lipsHandler(){
        self.coordinator?.selectFilterNotification(key: "EnhanceLipsFilter")
    }
    
    
    func skinHandler(){
        self.coordinator?.selectFilterNotification(key: "MaskedSkinSmoothingFilter")

//        let descriptor = filterManager.getFilterDescriptor(key: "MaskedSkinSmoothingFilter")
//        if descriptor != nil {
//            descriptor?.reset()
//            descriptor?.setParameter("inputAmount", value: 1.0)
//            descriptor?.setParameter("inputRadius", value: 16.0)
//
//            EditManager.addPreviewFilter(descriptor)
//            //self.coordinator?.selectFilterNotification(key: (descriptor?.key)!)
//            self.coordinator?.updateRequest(id: self.id)
//        } else {
//            log.error("Error creating skin filter")
//        }
    }
    
    func teethHandler(){
        self.coordinator?.selectFilterNotification(key: "EnhanceTeethFilter")
    }
    
    func eyesHandler(){
        self.coordinator?.selectFilterNotification(key: "EnhanceEyesFilter")
    }
    
    func eyebrowsHandler(){
        self.coordinator?.selectFilterNotification(key: "EnhanceEyebrowsFilter")
    }
    
    func autoHandler(){
        self.coordinator?.selectFilterNotification(key: "EnhanceFaceFilter")
        self.coordinator?.updateRequest(id: self.getId())
    }

    
} // EditFacesMenuController
//########################



