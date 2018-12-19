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

class EditBasicAdjustmentsController: UIViewController, EditChildControllerDelegate {
    
    
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
    //let editControlHeight: CGFloat = 64.0
    let editControlHeight: CGFloat = 48.0
    
    var childController:UIViewController? = nil
    
    
    // the list of controls (not sorted, so put in the order you want displayed)
    fileprivate var titleList: [String] = [ "White Balance", "Exposure", "Contrast", "Highlights & Shadows", "Clarity", "Dehaze", "Vibrance", "Saturation" ]
    
    // array of handlers. Order must match the names
    fileprivate lazy var handlerList:[()->()] = [wbHandler, exposureHandler, contrastHandler, highlightHandler, clarityHandler, dehazeHandler, vibranceHandler, saturationHandler]
    
    // array of icons for the controls
    fileprivate var iconList: [String] = [ "ic_wb", "ic_exposure", "ic_contrast", "ic_highlights", "ic_clarity", "ic_dehaze", "ic_vibrance", "ic_saturation" ]

    
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
        
        //view.backgroundColor = theme.backgroundColor
        view.backgroundColor = UIColor.clear

        // get display dimensions
        //displayHeight = view.height
        displayHeight = editControlHeight
        displayWidth = view.width
        
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        
        self.view.frame.size.height = displayHeight
        self.view.frame.size.width = displayWidth
        optionsControlView.frame.size.height = displayHeight
        optionsControlView.frame.size.width = displayWidth

        setupOptions()
        
        view.addSubview(optionsControlView)
        optionsControlView.fillSuperview()
        view.bringSubview(toFront: optionsControlView)
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
        menu.setTitles(titleList)
        menu.setHandlers(handlerList)
        menu.setIcons(iconList)
        menu.frame.size = optionsControlView.frame.size
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

    //////////////////////////////////////////
    // MARK: - Delegate functions for child controllers
    //////////////////////////////////////////
    
    // called when a child controller returns a filter selection
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
        optionsControlView.isHidden = false
    }

} // EditBasicAdjustmentsController
//########################



