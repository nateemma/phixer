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

    // special case flag - if a submenu enters a mode that follws the catgeory/filter scheme then we can handle prev/next using that
    private var filterCategoriesActive:Bool = false
    
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

    ////////////////////
    // Coordination Interface requests (forward/back)
    ////////////////////
    
    // get from FilterManager if valid, or just ignore
    override func nextItem() {
        if filterCategoriesActive {
            let key = filterManager.getNextFilterKey()
            self.coordinator?.selectFilterNotification(key: key)
        }
    }
    
    override func previousItem() {
        if filterCategoriesActive {
            let key = filterManager.getPreviousFilterKey()
            self.coordinator?.selectFilterNotification(key: key)
        }
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
        filterCategoriesActive = false
        switch (key){
        case "basic":
            basicAdjustmentsHandler()
        case "filters":
            filterCategoriesActive = true
            colorFiltersHandler()
        case "style":
            filterCategoriesActive = true
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
        self.coordinator?.activateRequest(id: ControllerIdentifier.hsvTool)
   }
    
    
    func styleTransferHandler(){
        filterManager.setCurrentCategory(FilterManager.styleTransferCategory)
        self.coordinator?.activateRequest(id: ControllerIdentifier.styleGallery)
    }

    func colorFiltersHandler(){
        // if category hasn't been set, jump to favourites, otherwise go to previous choice
        if filterManager.getCurrentCategory() == FilterManager.defaultCategory {
            filterManager.setCurrentCategory(FilterManager.favouriteCategory)
        }
        self.coordinator?.activateRequest(id: ControllerIdentifier.filterGallery)
    }
    
    func detailHandler(){
        self.coordinator?.activateRequest(id: ControllerIdentifier.detailTool)
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


