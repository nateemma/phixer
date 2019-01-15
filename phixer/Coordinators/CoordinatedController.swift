//
//  CoordinatedController.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit


// base class for ViewControllers that are part of the Coordinator approach

class CoordinatedController: UIViewController {
    
    
    // delegate for handling events
    weak var coordinator: CoordinatorDelegate? = nil
    
    // the type of controller (useful to the coordinator)
    public var controllerType: ControllerType = .fullscreen
    
    // indicates whether this Controller should show Google Ads
    public var showAds:Bool = false
    
    
    // flag to indicate whether interface (not device) is in landscape mode. TODO: move to UISettings?
    public var isLandscape: Bool { return checkLandscape() }

    // the current UI Theme. Note: this can change
    public var theme = ThemeManager.currentTheme()
    
    // FilterManager reference
    public var filterManager: FilterManager = FilterManager.sharedInstance
    
    
    //TODO: add titlebar and Ad views (and handling)?
    
    
    ////////////////////
    // Virtual funcs - should be overriden by subclass
    ////////////////////
    
    // do something if a filter was selected
    public func selectFilter(key: String){
        log.error("Base class called for key: \(key)")
    }
  
    public func nextFilter() -> String {
        log.error("Not supported by this Controller")
        return filterManager.getCurrentFilterKey()
    }
    
    public func previousFilter() -> String {
        log.error("Not supported by this Controller")
        return filterManager.getCurrentFilterKey()
    }

    // handle update of the UI
    public func requestUpdate(tag: String){
        log.error("Base class called by: \(tag)")
    }

    // return the display title for this Controller
    public func getTitle() -> String {
        return "ERROR: Base Class"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    public func getHelpKey() -> String {
        return "default"
    }
    
    ////////////////////
    // Useful funcs
    ////////////////////
    
    
    func clearSubviews(){
        for v in self.view.subviews{
            v.removeFromSuperview()
        }
    }

    
    func dismiss(){
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0 }) { _ in
                self.clearSubviews()
                self.view.isHidden = true
                self.coordinator?.notifyCompletion(tag: self.getTag())
        }
    }
    
    // get the tag used to identify this controller. Implemented as a func so that it gets the actual class, not the base class
    func getTag()->String{
        return "\(String(describing: type(of: self)))"
    }
    
    
    func checkLandscape() -> Bool {
        let sbo = UIApplication.shared.statusBarOrientation
        return ((sbo == .landscapeLeft) || (sbo == .landscapeRight))
    }
    
    
    func removeSubviews(){
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
    }
    
    
    ////////////////////
    // Default implementations of UIViewController funcs, mostly just for convenience and consistency
    ////////////////////
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("Low Memory Warning (\(self.getTag()))")
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /* restricting to portrait for now, so no need for these
     override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
     if ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight)) {
     log.verbose("Preparing for transition to Landscape")
     } else {
     log.verbose("Preparing for transition to Portrait")
     }
     }
     */
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        
        if ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight)){
            log.verbose("### Detected change to: Landscape")
        } else {
            log.verbose("### Detected change to: Portrait")
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.viewDidLoad()
    }
    
    
    // Autorotate configuration default behaviour. Override for something different
    
    //NOTE: only works for iOS 10 and later
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    
} // CoordinatedController
