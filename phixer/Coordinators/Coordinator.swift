//
//  Coordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit


// the base class for the Coordinator pattern

class Coordinator: CoordinatorDelegate {
    
    
    // the parent coordinator, if any
    weak var coordinator: CoordinatorDelegate? = nil
    
    static var navigationController: UINavigationController? = nil
    
    static var filterManager: FilterManager? = nil 
    
    
    // map of sub-coordinators
    var subCoordinators: [CoordinatorIdentifier:CoordinatorDelegate] = [:]
    
    // list of valid Controllers for this coordinator (state)
    var validControllers: [ControllerIdentifier] = []
    
    // Map of Controller to its associated Coordinator
    var coordinatorMap: [ControllerIdentifier:CoordinatorIdentifier] = [:]
    
    // the main ViewController. Ther can be only one!
    var mainController: CoordinatedController? = nil
    var mainControllerId: ControllerIdentifier = .help // have to default to something
    var mainControllerTag: String = ""
    
    // list of currently active sub-controllers. The key is the tag of the controller (retrieved when launched)
    var subControllers: [String:CoordinatedController] = [:]
    
    // completion handler for when this coordinator has finished (set by parent)
    var completionHandler:(()->())? = nil

    
    /////////////////////////
    // MARK: - Initializer
    /////////////////////////

    init() {
        self.completionHandler = nil
        self.subCoordinators = [:]
        self.validControllers = []
        self.mainController = nil
        self.subControllers = [:]
    }
    
    // get the tag used to identify this class. Implemented as a func so that it gets the actual class, not the base class
    func getTag()->String{
        return "\(String(describing: type(of: self)))"
    }

    /////////////////////////
    // MARK: - funcs to be overriden by subclass
    //         Note: default behaviour is sufficient in most cases.
    //               The main exceptions are:
    //               -  start() must be handled (unique to each coordinator)
    //               -  filter selection (e.g. in Editor screens)
    /////////////////////////

    
    // initiate processing. This is just in case the coordinator/app aove this needs to do something in between object creation and start of processing
    // MUST be overriden in subclass
    
    public func start(completion: @escaping ()->()){
        log.error("Base class called. Should have been be overriden")
        
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.validControllers = []
        self.mainController = nil
        self.subControllers = [:]
    }
    
    
    

    // Default implementations - generally pass on the request until something answers
    // Most of these should work if there is only one coordinator/controller active, but not if there are multiple
    
    // we're done with this coordinator, so call the completion handler
    public func back(){
        if self.completionHandler != nil {
            self.completionHandler!()
        }
    }
    
    
    // default selection. Pass on if there is only 1 active subcontroller
    public func selectFilter(key: String) {
        log.debug("default action")
        self.mainController?.selectFilter(key: key)
    }
    
    
    // default nextFilter. Pass on if there is only 1 sub-coordinator, else ask FilterManager (works for any Category-based list)
    public func nextFilter() -> String {
        var key:String = (Coordinator.filterManager?.getCurrentFilterKey())!
        
        if subCoordinators.count == 1 {
            for k in subCoordinators.keys {
                key = (subCoordinators[k]?.nextFilter())!
            }
        } else {
            log.error("Base class. Unable to route request")
            // key =  filterManager.getNextFilterKey() // TODO
        }
        return key
    }
    
    
    // default nextFilter. Pass on if there is only 1 sub-coordinator, else ask FilterManager (works for any Category-based list)
    public func previousFilter() -> String {
        var key:String = (Coordinator.filterManager?.getCurrentFilterKey())!
        
        if subCoordinators.count == 1 {
            for k in subCoordinators.keys {
                key = (subCoordinators[k]?.previousFilter())!
            }
        } else {
            log.error("Base class. Unable to route request")
            // key =  filterManager.getNextFilterKey() // TODO
        }
        return key
    }
    
    
    // default requestUpdate: pass on to all active controllers
    public func requestUpdate(tag: String) {
        self.mainController?.requestUpdate(tag: tag)
        /*** do we need to update the sub-controllers?
        if subControllers.count > 0 {
            for k in subControllers.keys {
                subControllers[k]?.requestUpdate(tag: tag)
            }
        }
         ***/
    }
    
    
    // default notifyCompletion: removes
    public func notifyCompletion(tag: String) {
        
        if tag == self.mainControllerTag {
            log.verbose("Main Controller finished: \(tag)")
            Coordinator.navigationController?.popViewController(animated: true)
        } else {
            if subControllers[tag] != nil {
                log.verbose("Sub-Controller finished: \(tag)")
                subControllers[tag]?.remove()
                subControllers[tag] = nil
            } else {
                log.error("Unkown Sub-Controller: \(tag)")
            }
        }
    }
    
    
    // default activate. Checks the list of valid controllers and starts it if valid. Should be OK as-is
    public func activate(_ controller: ControllerIdentifier) {
        
        guard self.validControllers.count > 0 else {
            log.error("Valid controller list is empty")
            return
        }
        guard self.validControllers.contains(controller) else {
            log.error("Controller (\(controller.rawValue) not valid in this state")
            return
        }
        
        //TODO: figure out if we need to start a new Coordinator to handle the Controller
        if self.coordinatorMap[controller] != nil {
            // need to start a new Coordinator
            log.info("start new Coordinator for: \(controller.rawValue)")
            self.startCoordinator(self.coordinatorMap[controller]!)
            
        } else {
        
            // OK to just start the controller
            log.verbose("Attempting to start: \(controller.rawValue)")
            let vc = ControllerFactory.getController(controller)
            if vc != nil {
                let tag = vc?.getTag()
                if let tag = tag {
                    
                    if vc?.controllerType == .fullscreen { // full screen controller
                        if controller == self.mainControllerId {
                            self.mainController = vc
                            self.mainControllerTag = tag
                        }
                        log.verbose("Pushing: \(tag)")
                       Coordinator.navigationController?.pushViewController(vc!, animated: true)
                    } else { // sub-controller
                        log.verbose("Adding sub-cntroller: \(tag)")
                       if self.subControllers[tag] != nil {
                            log.warning("Sub-Controller being replaced: \(controller.rawValue) (\(tag))")
                        }
                        self.subControllers[tag] = vc
                        self.mainController?.add(vc!)
                    }
                    vc?.coordinator = self
                    vc?.view.isHidden = false
                } else {
                    log.error ("No tag available for controller: \(controller.rawValue)")
                }
            } else {
                log.error("Error creating controller: \(controller.rawValue)")
            }
        }
    }
    
    
    // default help function
    public func help() {
        // use the help file associated with the main controller id
        let vc = ControllerFactory.getController(.help) as? HTMLViewController
        vc?.setTitle("Help: \((self.mainController?.getTitle())!)")
        vc?.loadFile(name: (self.mainController?.getHelpKey())!)
        
        // NOTE: if there are multiple possible help files, then this func must be overridden in the Coordinator
    }
    
    // // request to hide any subcontrollers that are active
    public func hideSubcontrollers() {
        if self.subControllers.count > 0 {
            for k in self.subControllers.keys {
                self.subControllers[k]?.view.isHidden = true
            }
        }
    }
    
    // // request to show any subcontrollers that are active
    public func showSubcontrollers() {
        if self.subControllers.count > 0 {
            for k in self.subControllers.keys {
                self.subControllers[k]?.view.isHidden = false
            }
        }
    }
    
    func startCoordinator(_ coordinator: CoordinatorIdentifier){
        if self.subCoordinators[coordinator] == nil {
            // not already running, so create
            self.subCoordinators[coordinator] = CoordinatorFactory.getCoordinator(coordinator)
        }
        if let subc = self.subCoordinators[coordinator] {
            //TODO: make sure tag and id match???
            subc.start(completion: { self.notifyCompletion(tag: coordinator.rawValue)} )
        }
    }

}
