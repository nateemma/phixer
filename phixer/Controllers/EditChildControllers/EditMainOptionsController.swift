//
//  EditMainOptionsController.swift
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

// This View Controller handles simple editing of a photo

class EditMainOptionsController: EditBaseMenuController {

    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        self.cancelButton?.isHidden = true // disable, since top level
    }
    
    
    //////////////////////////////////////////
    // MARK: - Override funcs for specifying items
    //////////////////////////////////////////
    
    
    // returns the text to display at the top of the window
    override func getTitle() -> String {
        self.cancelButton?.isHidden = true
        return "Edit Options"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "SimpleEditor"
    }
    
    // returns the list of titles for each item
    override func getItemList() -> [Adornment] {
        self.cancelButton?.isHidden = true
        return itemList
    }

    
    //////////////////////////////////////////
    // MARK: - Handlers for the menu items
    //////////////////////////////////////////
    
    fileprivate var itemList: [Adornment] = [ Adornment(key: "basic",      text: "Basic Adjustments", icon: "ic_basic", view: nil, isHidden: false),
                                              Adornment(key: "filters",    text: "Color Filters",     icon: "ic_filter", view: nil, isHidden: false),
                                              Adornment(key: "style",      text: "Style Transfer",    icon: "ic_brush", view: nil, isHidden: false),
                                              Adornment(key: "curves",     text: "Curves",            icon: "ic_curve", view: nil, isHidden: false),
                                              Adornment(key: "color",      text: "Color Adjustments", icon: "ic_adjust", view: nil, isHidden: false),
                                              Adornment(key: "detail",     text: "Detail",            icon: "ic_sharpness", view: nil, isHidden: false),
                                              Adornment(key: "transforms", text: "Transforms",        icon: "ic_transform", view: nil, isHidden: false),
                                              Adornment(key: "faces",      text: "Faces",             icon: "ic_face", view: nil, isHidden: false),
                                              Adornment(key: "presets",    text: "Presets",           icon: "ic_preset", view: nil, isHidden: false) ]

    
    override func handleSelection(key: String){
        switch (key){
        case "basic":
            basicAdjustmentsHandler()
        case "filters":
            colorFiltersHandler()
        case "style":
            styleTransferHandler()
        case "curves":
            curvesHandler()
        case "color":
            colorAdjustmentsHandler()
        case "detail":
            detailHandler()
        case "transforms":
            transformsHandler()
        case "faces":
            facesHandler()
        case "presets":
            presetsHandler()
        default:
            log.error("Unknown key: \(key)")
        }
    }

    func basicAdjustmentsHandler(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.editBasicAdjustmentsMenu)
    }
    
    func colorAdjustmentsHandler(){
        notYetImplemented()
    }
    
    
    func styleTransferHandler(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.browseStyleTransfer)
    }

    func colorFiltersHandler(){
        // jump straight to the 'Favourites' category
        filterManager.setCurrentCategory(FilterManager.favouriteCategory)
        self.coordinator?.activateRequest(id: ControllerIdentifier.filterGallery)
    }
    
    func detailHandler(){
        notYetImplemented()
    }
    
    func curvesHandler(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.curveTool)
    }
    
    func transformsHandler(){
        notYetImplemented()
    }
    
    func facesHandler(){
        notYetImplemented()
    }
    
    func presetsHandler(){
        notYetImplemented()
    }
    


} // EditMainOptionsController
//########################


