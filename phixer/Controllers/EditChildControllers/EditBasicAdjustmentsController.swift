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
        return [ "White Balance", "Exposure", "Contrast", "Highlights & Shadows", "Clarity", "Dehaze", "Vibrance", "Saturation" ]
    }
    
    // returns the list of handlers for each item
    override func getHandlerList() -> [()->()] {
        return [wbHandler, exposureHandler, contrastHandler, highlightHandler, clarityHandler, dehazeHandler, vibranceHandler, saturationHandler]
    }
    
    // returns the list of icons for each item - can be empty or contan empty ("") items
    override func getIconList() -> [String] {
        return[ "ic_wb", "ic_exposure", "ic_contrast", "ic_highlights", "ic_clarity", "ic_dehaze", "ic_vibrance", "ic_saturation" ]
    }
    
    
    //////////////////////////////////////////
    // MARK: - Handlers for the menu items
    //////////////////////////////////////////

    func wbHandler(){
        self.delegate?.editFilterSelected(key: "CITemperatureAndTint")
    }
    
    func exposureHandler(){
        self.delegate?.editFilterSelected(key: "CIExposureAdjust")
    }
    
    func contrastHandler(){
        self.delegate?.editFilterSelected(key: "CIColorControls")
    }
    
    func highlightHandler(){
        self.delegate?.editFilterSelected(key: "CIHighlightShadowAdjust")
    }
    
    func clarityHandler(){
        self.delegate?.editFilterSelected(key: "ClarityFilter")
    }
    
    func dehazeHandler(){
        notYetImplemented()
    }
    
    func vibranceHandler(){
        self.delegate?.editFilterSelected(key: "CIVibrance")
    }
    
    func saturationHandler(){
        self.delegate?.editFilterSelected(key: "CIColorControls")
    }

} // EditBasicAdjustmentsController
//########################



