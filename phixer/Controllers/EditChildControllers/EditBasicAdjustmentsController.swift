//
//  EditBasicAdjustmentsController.swift
//  phixer
//
//  Created by Philip Price on 12/17/18
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon
import iCarousel



private var filterList: [String] = []
private var filterCount: Int = 0

// This View Controller handles the menu and options for Basic Adjustments

class EditBasicAdjustmentsController: EditBaseMenuController {
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
    }
    
    
    //////////////////////////////////////////
    // MARK: - Override funcs for specifying items
    //////////////////////////////////////////
    
    
    // returns the text to display at the top of the window
    override func getTitle() -> String {
        return "Basic Adjustments"
    }

    // returns the list of titles for each item
    override func getItemList() -> [Adornment] {
        return itemList
    }

    
    // Adornment list
    fileprivate var itemList: [Adornment] = [ Adornment(key: "exposure",   text: "Exposure",             icon: "ic_exposure", view: nil, isHidden: false),
                                              Adornment(key: "brightness", text: "Brightness",           icon: "ic_brightness", view: nil, isHidden: false),
                                              Adornment(key: "contrast",   text: "Contrast",             icon: "ic_contrast", view: nil, isHidden: false),
                                              Adornment(key: "clarity",    text: "Clarity",              icon: "ic_clarity", view: nil, isHidden: false),
                                              Adornment(key: "highlights", text: "Highlights & Shadows", icon: "ic_highlights", view: nil, isHidden: false),
                                              Adornment(key: "wb",         text: "White Balance",        icon: "ic_wb", view: nil, isHidden: false),
                                              Adornment(key: "dehaze",     text: "Dehaze",               icon: "ic_dehaze", view: nil, isHidden: false),
                                              Adornment(key: "vibrance",   text: "Vibrance",             icon: "ic_vibrance", view: nil, isHidden: false),
                                              Adornment(key: "saturation", text: "Saturation",           icon: "ic_saturation", view: nil, isHidden: false),
                                              Adornment(key: "vignette",   text: "Vignette",             icon: "ic_vignette", view: nil, isHidden: false) ]

    // handler for selected adornments:
    override func handleSelection(key:String){
        switch (key){
        case "exposure": exposureHandler()
        case "brightness": brightnessHandler()
        case "contrast": contrastHandler()
        case "clarity": clarityHandler()
        case "highlights": highlightHandler()
        case "wb": wbHandler()
        case "dehaze": dehazeHandler()
        case "vibrance": vibranceHandler()
        case "saturation": saturationHandler()
        case "vignette": vignetteHandler()
        default:
            log.error("Unknown key: \(key)")
        }
    }

    //////////////////////////////////////////
    // MARK: - Handlers for the menu items
    //////////////////////////////////////////

    func wbHandler(){
        self.coordinator?.selectFilter(key: "WhiteBalanceFilter")
    }
    
    func exposureHandler(){
        self.coordinator?.selectFilter(key: "CIExposureAdjust")
    }
    
    func brightnessHandler(){
        self.coordinator?.selectFilter(key: "BrightnessFilter")
    }
    
    func contrastHandler(){
        self.coordinator?.selectFilter(key: "ContrastFilter")
    }
    
    func clarityHandler(){
        self.coordinator?.selectFilter(key: "ClarityFilter")
    }

    func highlightHandler(){
        self.coordinator?.selectFilter(key: "CIHighlightShadowAdjust")
    }
    
    func vignetteHandler(){
        self.coordinator?.selectFilter(key: "CIVignetteEffect")
    }
    
    func dehazeHandler(){
        self.coordinator?.selectFilter(key: "DehazeFilter")
    }
    
    func vibranceHandler(){
        self.coordinator?.selectFilter(key: "CIVibrance")
    }
    
    func saturationHandler(){
        self.coordinator?.selectFilter(key: "SaturationFilter")
    }

    

    
} // EditBasicAdjustmentsController
//########################



