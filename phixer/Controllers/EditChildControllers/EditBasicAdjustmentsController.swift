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

class EditBasicAdjustmentsController: EditBaseController {
    
    
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
    override func getTitleList() -> [String] {
        return [ "Exposure", "Brightness", "Contrast", "Highlights & Shadows", "White Balance", "Dehaze", "Vibrance", "Saturation", "Vignette" ]
    }
    
    // returns the list of handlers for each item
    override func getHandlerList() -> [()->()] {
        return [exposureHandler, brightnessHandler, contrastHandler, highlightHandler, wbHandler, dehazeHandler, vibranceHandler, saturationHandler, vignetteHandler]
    }
    
    // returns the list of icons for each item - can be empty or contan empty ("") items
    override func getIconList() -> [String] {
        return[ "ic_exposure", "ic_brightness", "ic_contrast", "ic_highlights", "ic_wb", "ic_dehaze", "ic_vibrance", "ic_saturation", "ic_vignette" ]
    }
    
    

    //////////////////////////////////////////
    // MARK: - Handlers for the menu items
    //////////////////////////////////////////

    func wbHandler(){
        self.delegate?.editFilterSelected(key: "WhiteBalanceFilter")
    }
    
    func exposureHandler(){
        self.delegate?.editFilterSelected(key: "CIExposureAdjust")
    }
    
    func brightnessHandler(){
        self.delegate?.editFilterSelected(key: "BrightnessFilter")
    }
    
    func contrastHandler(){
        self.delegate?.editFilterSelected(key: "ContrastFilter")
    }

    func highlightHandler(){
        self.delegate?.editFilterSelected(key: "CIHighlightShadowAdjust")
    }
    
    func vignetteHandler(){
        self.delegate?.editFilterSelected(key: "CIVignetteEffect")
    }
    
    func dehazeHandler(){
        self.delegate?.editFilterSelected(key: "DehazeFilter")
    }
    
    func vibranceHandler(){
        self.delegate?.editFilterSelected(key: "CIVibrance")
    }
    
    func saturationHandler(){
        self.delegate?.editFilterSelected(key: "SaturationFilter")
    }

} // EditBasicAdjustmentsController
//########################



