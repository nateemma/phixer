//
//  EditDetailToolController.swift
//  phixer
//
//  Created by Philip Price on 01/27/19
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon
import CoreImage



// This View Controller is a Tool Subcontroller that provides the ability to apply "Details"-type filters, i.e. various Sharpening approaches, noise reduction etc

class EditDetailMenuController: EditBaseMenuController {
    

 
    ////////////////////
    // Override base class defaults
    ////////////////////
    
    override func getTitle() -> String{
        return "Adjust Details"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "SimpleEditor" // TODO: write custom help file
    }
    
 
    override func end() {
        releaseFilters()
         dismiss()
    }

    
   
    ////////////////////
    // Menu setup
    ////////////////////
    
    // returns the list of titles for each item
    override func getItemList() -> [Adornment] {
        return itemList
    }
    
    fileprivate var itemList: [Adornment] = [ Adornment(key: "unsharp",    text: "Unsharp Mask"),
                                              Adornment(key: "luminosity", text: "Luminosity Sharpening"),
                                              Adornment(key: "hipass",     text: "High-Pass Sharpening"),
                                              Adornment(key: "clarity",    text: "Clarity"),
                                              Adornment(key: "denoise",    text: "Noise Reduction"),
                                              Adornment(key: "soft",       text: "Preset: Soft Subject"),
                                              Adornment(key: "portrait",   text: "Preset: Portrait"),
                                              Adornment(key: "moderate",   text: "Preset: Moderate"),
                                              Adornment(key: "maximum",    text: "Preset: Maximum"),
                                              Adornment(key: "allpurpose", text: "Preset: All-Purpose"),
                                              Adornment(key: "faces",      text: "Preset: Faces"),
                                              Adornment(key: "landscape",  text: "Preset: Landscape")  ]

    
    override func handleSelection(key: String){
        var descriptor: FilterDescriptor? = nil
        
        // Note: for the 'preset' options, we need to set the parameters. For other options, leave them alone
        switch (key){
        case "unsharp":
            descriptor = filterManager.getFilterDescriptor(key: "UnsharpMaskFilter")
            //descriptor?.reset()
            
        case "luminosity":
            descriptor = filterManager.getFilterDescriptor(key: "CISharpenLuminance")
            
        case "hipass":
            descriptor = filterManager.getFilterDescriptor(key: "HighPassSharpeningFilter")
            descriptor?.setParameter("inputRadius", value: 4.0)
            descriptor?.setParameter("inputThreshold", value: 0.01)
            
        case "clarity":
            descriptor = filterManager.getFilterDescriptor(key: "ClarityFilter")
            
        case "denoise":
            descriptor = filterManager.getFilterDescriptor(key: "CINoiseReduction")
            
        case "soft":
            descriptor = filterManager.getFilterDescriptor(key: "UnsharpMaskFilter")
            descriptor?.setParameter("inputAmount", value: 1.5)
            descriptor?.setParameter("inputRadius", value: 1.0)
            descriptor?.setParameter("inputThreshold", value: 10.0)
            
        case "portrait":
            descriptor = filterManager.getFilterDescriptor(key: "UnsharpMaskFilter")
            descriptor?.setParameter("inputAmount", value: 0.75)
            descriptor?.setParameter("inputRadius", value: 2.0)
            descriptor?.setParameter("inputThreshold", value: 3.0)
            
        case "moderate":
            descriptor = filterManager.getFilterDescriptor(key: "UnsharpMaskFilter")
            descriptor?.setParameter("inputAmount", value: 1.2)
            descriptor?.setParameter("inputRadius", value: 1.0)
            descriptor?.setParameter("inputThreshold", value: 3.0)
            
            
        case "maximum":
            descriptor = filterManager.getFilterDescriptor(key: "UnsharpMaskFilter")
            descriptor?.setParameter("inputAmount", value: 0.65)
            descriptor?.setParameter("inputRadius", value: 4.0)
            descriptor?.setParameter("inputThreshold", value: 3.0)
            
        case "allpurpose":
            descriptor = filterManager.getFilterDescriptor(key: "UnsharpMaskFilter")
            descriptor?.setParameter("inputAmount", value: 0.85)
            descriptor?.setParameter("inputRadius", value: 1.0)
            descriptor?.setParameter("inputThreshold", value: 4.0)
            
        case "faces":
            descriptor = filterManager.getFilterDescriptor(key: "UnsharpMaskFilter")
            descriptor?.setParameter("inputAmount", value: 0.35)
            descriptor?.setParameter("inputRadius", value: 1.4)
            descriptor?.setParameter("inputThreshold", value: 15.0)
            
        case "landscape":
            descriptor = filterManager.getFilterDescriptor(key: "UnsharpMaskFilter")
            descriptor?.setParameter("inputAmount", value: 0.40)
            descriptor?.setParameter("inputRadius", value: 0.8)
            descriptor?.setParameter("inputThreshold", value: 35.0)
            
        default:
            log.error("Unknown key: \(key)")
        }
        
        if descriptor != nil {
            self.coordinator?.selectFilterNotification(key: (descriptor?.key)!)
            self.coordinator?.updateRequest(id: self.id) // we are using the same filter a lot, so we have to explicitly request an update
        }
    }

    ////////////////////////
    // Filter Management
    ////////////////////////
    
    let filterList = ["UnsharpMaskFilter", "CISharpenLuminance", "HighPassSharpeningFilter", "ClarityFilter", "CINoiseReduction"]
    
    private func preloadFilters(){
        for f in filterList {
            _ = filterManager.getFilterDescriptor(key: f)
        }
    }
    
    private func releaseFilters(){
        for f in filterList {
            filterManager.releaseFilterDescriptor(key: f)
        }
    }
    
}
