//
//  EditCurvesController.swift
//  phixer
//
//  Created by Philip Price on 01/07/19
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon
import iCarousel



private var filterList: [String] = []
private var filterCount: Int = 0

// This View Controller handles the menu and options for Curves and Histogram

class EditCurvesController: EditBaseMenuController {
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
    }
    
    
    //////////////////////////////////////////
    // MARK: - Override funcs for specifying items
    //////////////////////////////////////////
    
    
    // returns the text to display at the top of the window
    override func getTitle() -> String {
        return "Curves & Histogram"
    }

    // returns the list of titles for each item
    override func getItemList() -> [Adornment] {
        return itemList
    }

    
    // Adornment list
    fileprivate var itemList: [Adornment] = [ Adornment(key: "histogram", text: "Histogram", icon: "", view: nil, isHidden: false),
                                              Adornment(key: "curve", text: "Edit Curve", icon: "", view: nil, isHidden: false),
                                              Adornment(key: "preset", text: "Curve Presets", icon: "", view: nil, isHidden: false) ]

    // handler for selected adornments:
    override func handleSelection(key:String){
        switch (key){
        case "histogram": histogramHandler()
        case "curve": curveHandler()
        case "preset": curvePresetHandler()
        default:
            log.error("Unknown key: \(key)")
        }
    }

    //////////////////////////////////////////
    // MARK: - Handlers for the menu items
    //////////////////////////////////////////

    func histogramHandler(){
        notYetImplemented()
    }
    
    func curveHandler(){
        notYetImplemented()
    }
    
    func curvePresetHandler(){
        notYetImplemented()
    }
    

} // EditCurvesController
//########################



