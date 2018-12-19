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

class EditMainOptionsController: UIViewController, EditChildControllerDelegate {
    
    
    // delegate for issuing callbacks. Must be set by the parent controller
    public var delegate: EditChildControllerDelegate? = nil
    
    var theme = ThemeManager.currentTheme()
    
    
 
    // The Edit controls/options
    var optionsControlView: UIView! = UIView()
    
    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let buttonSize : CGFloat = 48.0
    let editControlHeight: CGFloat = 64.0
    
    var childController:UIViewController? = nil
    
    
    // the list of controls (not sorted, so put in the order you want displayed)
    fileprivate var optionNameList: [String] = [ "Basic Adjustments", "Color Adjustments", "Style Transfer", "Color Filters", "Detail", "Curves", "Transforms", "Faces", "Presets" ]
    
    // array of handlers. Order must match the names
    fileprivate lazy var optionHandlerList:[()->()] = [basicAdjustmentsHandler, colorAdjustmentsHandler, styleTransferHandler, colorFiltersHandler, detailHandler,
                                                       curvesHandler, transformsHandler, facesHandler, presetsHandler]

    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Logging nicety, show that controller has changed. Not using the logging API so that this stands out more
        print ("\n========== \(String(describing: self)) ==========")

        doInit()
        
      // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        view.backgroundColor = UIColor.clear

        // get display dimensions
        //displayHeight = view.height
        displayHeight = editControlHeight
        displayWidth = view.width
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        
        optionsControlView.frame.size.height = displayHeight
        optionsControlView.frame.size.width = displayWidth
        
        setupOptions()
        
        view.addSubview(optionsControlView)
        optionsControlView.fillSuperview()
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("Low Memory Warning")
        // Dispose of any resources that can be recreated.
    }
    
    
    //////////////////////////////////////
    // MARK: - Sub-View layout
    //////////////////////////////////////

    private func setupOptions() {
        let menu = SimpleCarousel()
        menu.setTitles(optionNameList)
        menu.setHandlers(optionHandlerList)
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
        let vc = StyleTransferGalleryViewController()
        vc.delegate = self
        vc.mode = .returnSelection
        present(vc, animated: true, completion: { })
    }

    func colorFiltersHandler(){
        let vc = FilterGalleryViewController()
        vc.delegate = self
        vc.mode = .returnSelection
        present(vc, animated: true, completion: { })
    }
    
    func detailHandler(){
        notYetImplemented()
    }
    
    func curvesHandler(){
        notYetImplemented()
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
    func editFilterSelected(key: String) {
        // just pass on the to the parent controller
        if self.delegate != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.editFilterSelected(key: key)
            })
        }
    }

    // called when a child controller has done something that requires the main UI to be updated
    func editRequestUpdate() {
        // just pass on the to the parent controller
        if self.delegate != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.editRequestUpdate()
            })
        }
    }
    
    // called when a child controller has finished
    func editFinished(){
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


// GalleryViewControllerDelegate(s)

extension EditMainOptionsController: GalleryViewControllerDelegate {
    func galleryCompleted() {
        DispatchQueue.main.async(execute: { () -> Void in
            log.verbose("Returned from gallery")
            self.childController?.remove()
            self.childController = nil
            self.optionsControlView.isHidden = false
       })
        
    }
    
    func gallerySelection(key: String) {
        log.debug("Filter selection: \(key)")
        // just pass on the to the parent controller
        if self.delegate != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.editFilterSelected(key: key)
            })
        }
    }
}

