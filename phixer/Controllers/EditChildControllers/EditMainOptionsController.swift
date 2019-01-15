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

class EditMainOptionsController: CoordinatedController {

    
    let menu = SimpleCarousel()

 
    // The Edit controls/options
    var optionsControlView: UIView! = UIView()
    
    
    // var isLandscape : Bool = false // moved to base class
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let buttonSize : CGFloat = 32.0
    //let editControlHeight: CGFloat = 96.0
    let editControlHeight: CGFloat = 72.0

    
    /////////////////////////////
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    

    private var initDone:Bool = false
    
    private func doInit(){
        
        if !initDone {
            initDone = true
        }
    }

    /////////////////////////////

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Logging nicety, show that controller has changed. Not using the logging API so that this stands out more
        print ("\n========== \(String(describing: type(of: self))) ==========")

        doInit()
        
        
      // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = UIColor.clear
        

        // get display dimensions
        //displayHeight = view.height
        displayHeight = view.height
        displayWidth = view.width
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        /***
        // resize the main view so that it doesn't block the previous controller
        //self.view.frame.origin.x = 0.0
        //self.view.frame.origin.y = displayHeight - editControlHeight
        self.view.frame.size.height = editControlHeight
        self.view.frame.size.width = displayWidth
        self.view.anchorToEdge(.bottom, padding: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        ***/
        
        optionsControlView.frame.size.height = editControlHeight
        optionsControlView.frame.size.width = displayWidth

        setupOptions()
        
        view.addSubview(optionsControlView)
        optionsControlView.anchorToEdge(.bottom, padding: 0, width: optionsControlView.frame.size.width, height: optionsControlView.frame.size.height)
        //optionsControlView.fillSuperview()

        
    }
    
    
    //////////////////////////////////////
    // MARK: - Accessors
    //////////////////////////////////////
    
    
    override func nextFilter() -> String {
        log.debug("next...")
        return menu.getNextItem()
    }
    
    override func previousFilter() -> String {
        log.debug("previous...")
        return menu.getPreviousItem()
    }
    


    //////////////////////////////////////
    // MARK: - Sub-View layout
    //////////////////////////////////////

    private func setupOptions() {
        menu.setItems(optionList)
        menu.delegate = self
        optionsControlView.addSubview(menu)
        menu.fillSuperview()
    }


    //////////////////////////////////////////
    // MARK: - Not yet implemented notifier
    //////////////////////////////////////////
    
    func notYetImplemented(){
        DispatchQueue.main.async(execute: { () -> Void in
            let alert = UIAlertController(title: "Oh Dear", message: "Not yet implemented. Sorry!", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in alert.dismiss(animated: true, completion: nil)} )
        })
    }
    
    
 
  
    //////////////////////////////////////////
    // MARK: - Handlers for the menu items
    //////////////////////////////////////////

    fileprivate var optionList: [Adornment] = [ Adornment(key: "basic",      text: "Basic Adjustments", icon: "ic_basic", view: nil, isHidden: false),
                                                Adornment(key: "filters",    text: "Color Filters",     icon: "ic_filter", view: nil, isHidden: false),
                                                Adornment(key: "style",      text: "Style Transfer",    icon: "ic_brush", view: nil, isHidden: false),
                                                Adornment(key: "curves",     text: "Curves",            icon: "ic_curve", view: nil, isHidden: false),
                                                Adornment(key: "color",      text: "Color Adjustments", icon: "ic_adjust", view: nil, isHidden: false),
                                                Adornment(key: "detail",     text: "Detail",            icon: "ic_sharpness", view: nil, isHidden: false),
                                                Adornment(key: "transforms", text: "Transforms",        icon: "ic_transform", view: nil, isHidden: false),
                                                Adornment(key: "faces",      text: "Faces",             icon: "ic_face", view: nil, isHidden: false),
                                                Adornment(key: "presets",    text: "Presets",           icon: "ic_preset", view: nil, isHidden: false) ]

    
    func handleSelection(key: String){
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
        self.coordinator?.activate(ControllerIdentifier.editBasicAdjustmentsMenu)
    }
    
    func colorAdjustmentsHandler(){
        notYetImplemented()
    }
    
    
    func styleTransferHandler(){
        self.coordinator?.activate(ControllerIdentifier.styleTransfer)
    }

    func colorFiltersHandler(){
        // jump straight to the 'Favourites' category
        filterManager.setCurrentCategory(FilterManager.favouriteCategory)
        self.coordinator?.activate(ControllerIdentifier.filterGallery)
    }
    
    func detailHandler(){
        notYetImplemented()
    }
    
    func curvesHandler(){
        self.coordinator?.activate(ControllerIdentifier.curveTool)
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


//########################
//MARK: Extensions
//########################


// Adornment delegate

extension EditMainOptionsController: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.handleSelection(key: key)
        })
    }
}
