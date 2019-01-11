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

class EditMainOptionsController: FilterBasedController, FilterBasedControllerDelegate {

    
    var theme = ThemeManager.currentTheme()
    
    let menu = SimpleCarousel()

 
    // The Edit controls/options
    var optionsControlView: UIView! = UIView()
    
    
    // var isLandscape : Bool = false // moved to base class
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let buttonSize : CGFloat = 32.0
    let editControlHeight: CGFloat = 96.0
    
    //var childController:EditBaseMenuController? = nil
    var childController:FilterBasedController? = nil
    var fullScreenController:FilterBasedController? = nil

    fileprivate var filterManager: FilterManager? = FilterManager.sharedInstance
    
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
        print ("\n========== \(String(describing: self)) ==========")

        doInit()
        
        childController = nil
        fullScreenController = nil
        
      // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = UIColor.clear

        // get display dimensions
        //displayHeight = view.height
        displayHeight = editControlHeight
        displayWidth = view.width
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        
        optionsControlView.frame.size.height = displayHeight
        optionsControlView.frame.size.width = displayWidth
        
        setupOptions()
        
        view.addSubview(optionsControlView)
        optionsControlView.fillSuperview()
        
        childController = nil
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("Low Memory Warning")
        // Dispose of any resources that can be recreated.
    }
    
    
    //////////////////////////////////////
    // MARK: - Accessors
    //////////////////////////////////////
    
    override func nextFilter(){
        log.debug("next...")
        if self.childController != nil {
            self.childController?.nextFilter()
        } else if self.fullScreenController != nil {
            self.fullScreenController?.nextFilter()
        } else {
            menu.nextItem()
        }
    }
    
    override func previousFilter(){
        log.debug("previous...")
        if self.childController != nil {
            self.childController?.previousFilter()
        } else if self.fullScreenController != nil {
            self.fullScreenController?.previousFilter()
        } else {
            menu.previousItem()
        }
    }
    
    override func show(){
        if self.childController != nil {
            self.childController?.show()
        } else if self.fullScreenController != nil {
            self.fullScreenController?.show()
       } else {
            self.show()
        }
    }
    
    override func hide(){
        if self.childController != nil {
            self.childController?.hide()
        } else if self.fullScreenController != nil {
            self.fullScreenController?.hide()
        } else {
            self.hide()
        }
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
                                                Adornment(key: "detail",     text: "Detail",            icon: "ic_sharpenness", view: nil, isHidden: false),
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
        self.optionsControlView.isHidden = true
        let vc = EditBasicAdjustmentsController()
        vc.delegate = self
        vc.view.frame.size = self.view.frame.size
        //present(vc, animated: true, completion: { })
        self.childController = vc
        add(childController!)
    }
    
    func colorAdjustmentsHandler(){
        notYetImplemented()
    }
    
    
    func styleTransferHandler(){
        fullScreenController = StyleTransferGalleryViewController()
        fullScreenController?.delegate = self
        fullScreenController?.mode = .returnSelection
        present(fullScreenController!, animated: true, completion: { })
    }

    func colorFiltersHandler(){
        // jump straight to the 'Favourites' category
        filterManager?.setCurrentCategory(FilterManager.favouriteCategory)
        
        fullScreenController = FilterGalleryViewController()
        fullScreenController?.delegate = self
        fullScreenController?.mode = .returnSelection
        present(fullScreenController!, animated: true, completion: { })
    }
    
    func detailHandler(){
        notYetImplemented()
    }
    
    func curvesHandler(){
        self.optionsControlView.isHidden = true
        let vc = EditCurvesController()
        vc.delegate = self
        vc.view.frame.size = self.view.frame.size
        self.childController = vc
        add(childController!)
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
    

    //////////////////////////////////////////
    // MARK: - Delegate functions for child controllers
    //////////////////////////////////////////
    
    // called when a child controller has selected a filter
    func filterControllerSelection(key: String) {
        // just pass on the to the parent controller
        if self.delegate != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.filterControllerSelection(key: key)
            })
        }
    }

    // called when a child controller has done something that requires the main UI to be updated
    func filterControllerUpdateRequest(tag: String) {
        // just pass on the to the parent controller
        if self.delegate != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.filterControllerUpdateRequest(tag: self.getTag())
            })
        }
    }
    
    // called when a child controller has finished
    func filterControllerCompleted(tag: String){
        // remove the child controller and re-display the main options (assuming only 1 level of sub-functionality here)
        self.childController?.remove()
        self.childController = nil
        self.optionsControlView.isHidden = false
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
