//
//  FilterBasedController.swift
//  phixer
//
//  Created by Philip Price on 01/10/19
//  Copyright © 2018 Nateemma. All rights reserved.
//


import Foundation
import UIKit

// This protocol should be used for Controllers that display a set of filters
// This is useful because the top level controllers can treat subcontrollers in a  generic fashion when navigating filters

// enum type that controls the behaviour of a gallery (grid-style image selection) view controller
// The intent is to allow galleries to operate as standalone controllers, or as part of a collection of controlllers,
// e.g. as part of a compound editing flow


class FilterBasedController: UIViewController {
    
    
   
    enum SelectionMode {
        case displaySelection
        case returnSelection
    }

    
    // operating mode, OK to set externally
    public var mode:SelectionMode = .displaySelection

    // delegate for handling events
    weak var delegate: FilterBasedControllerDelegate? = nil

    
    ////////////////////
    // 'Virtual' funcs, these can/should be overidden by the subclass
    ////////////////////
 
    // go to the next filter, whatever that means for this controller (if anything).
    func nextFilter(){
        log.debug("next not implemented for this controller... (\(self.getTag())))")
    }
    
    // go to the previous filter, whatever that means for this controller (if anything).
    func previousFilter(){
        log.debug("previous not implemented for this controller... (\(self.getTag()))")
    }
    
    // show this view
    func show(){
        self.view.isHidden = false
    }
    
    // hide this view
    func hide(){
        self.view.isHidden = true
    }

    // get the tag used to identify this controller. Implemented as a func so that it gets the actual class, not the base class
    func getTag()->String{
        return "\(String(describing: type(of: self)))"
    }
    
    ////////////////////
    // Default implementations
    ////////////////////

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("Low Memory Warning (\(self.getTag()))")
        // Dispose of any resources that can be recreated.
    }


    
    /* restricting to portrait for now, so no need for these
     override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
         if UIDevice.current.orientation.isLandscape {
             log.verbose("Preparing for transition to Landscape")
         } else {
             log.verbose("Preparing for transition to Portrait")
         }
     }
     */

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.current.orientation.isLandscape{
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
    
} // FilterBasedController
//########################

