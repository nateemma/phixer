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

    
    // id of the current Coordinator
    var id: CoordinatorIdentifier

    // the parent coordinator, if any
    weak var coordinator: CoordinatorDelegate? = nil
    
    static var navigationController: UINavigationController? = nil
    
    // completion handler for when this coordinator has finished (set by parent)
    var completionHandler:(()->())? = nil
    
    // reference to the FilterManager
    static var filterManager: FilterManager? = nil

    
    // map of sub-coordinators
    var subCoordinators: [CoordinatorIdentifier:CoordinatorDelegate] = [:]
    
    // list of valid Controllers for this coordinator (state)
    var validControllers: [ControllerIdentifier] = []
    
    // Map of Controller to its associated Coordinator
    var coordinatorMap: [ControllerIdentifier:CoordinatorIdentifier] = [:]
    
    // the main ViewController. There can be only one!
    var mainController: CoordinatedController? = nil
    var mainControllerId: ControllerIdentifier = .none // have to default to something
    var mainControllerTag: String = ""
    
    // list of currently active sub-controllers. The key is the id of the controller
    var subControllers: [ControllerIdentifier:CoordinatedController] = [:]

    // the ID of the currently active sub-controller. Note that it is not required for one to be active (only complicated activities will have them)
    var currSubController: ControllerIdentifier = .none
    
    // stack of subcontrollers
    var subControllerStack:Stack = Stack<ControllerIdentifier>()
    
    
    
    // a way to share keyed data between Coordinators
    static var sharedInfo:[String:String] = [:]
    
    /////////////////////////
    // MARK: - Initializer
    /////////////////////////

    init() {
        self.completionHandler = nil
        self.subCoordinators = [:]
        self.validControllers = []
        self.mainController = nil
        self.subControllers = [:]
        self.coordinator = nil
        self.id = .none
        
        self.currSubController = .none
    }
    
    // get the tag used to identify this class. Implemented as a func so that it gets the actual class, not the base class
    func getTag()->String{
        return "\(String(describing: type(of: self)))"
    }

    /////////////////////////
    // MARK: - funcs to be overriden by subclass
    //         Note: default behaviour is sufficient in most cases.
    //               The main exceptions are:
    //               -  startRequest() must be handled (unique to each coordinator)
    //               -  selectFilterNotification (e.g. in Editor screens)
    /////////////////////////
    
    func startRequest(completion: @escaping () -> ()) {
        
        // initiate processing. This is just in case the coordinator/app aove this needs to do something in between object creation and start of processing
        // MUST be overriden in subclass
        
        print ("\n========== \(String(describing: type(of: self))) ==========\n")
        log.error("ERROR: Base class called. Should have been be overriden")
        
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.validControllers = []
        self.mainController = nil
        self.subControllers = [:]
    }
        
    
    // default selection. Pass on to the main controller. Intercept this in the subclass if you need to do something different, e.g. launch another screen
    func selectFilterNotification(key: String) {
        log.debug("default action")
        DispatchQueue.main.async(execute: { self.mainController?.selectFilter(key: key) })
    }

    
    // Default implementations - generally pass on the request until something answers
    // Most of these should work if there is only one coordinator/controller active, but not if there are multiple

    
    // sets the coordinator parent
    func setCoordinator(_ coordinator:Coordinator){
        self.coordinator = coordinator
    }

    
    func endRequest() {
        // we're done with this coordinator, so call the completion handler

        // not sure if we need this. Should probably notify anything active to stop
//        if self.completionHandler != nil {
//            self.completionHandler!()
//        }

    }
    
    
    
    // move to the next item, whatever that is (can be nothing)
    func nextItemRequest() {
        
        if subControllers.count > 0 {
            if let id = subControllerStack.top {
                if let sc = subControllers[id] as? SubControllerDelegate {
                    DispatchQueue.main.async(execute: { sc.previousItem() })
                } else {
                    log.error("Could not get reference to subcontroller: \(id)")
                }
            }
        } else {
            log.error("No sub-controllers - unable to route request")
         }
    }
    
    
    
    // move to the previous item, whatever that is (can be nothing)
    func previousItemRequest() {
        
        if subControllers.count > 0 {
            if let id = subControllerStack.top {
                if let sc = subControllers[id] as? SubControllerDelegate {
                    DispatchQueue.main.async(execute: { sc.nextItem() })
                } else {
                    log.error("Could not get reference to subcontroller: \(id)")
                }
            }
        } else {
            log.error("No sub-controllers - unable to route request")
        }
    }

    

    // default notifyCompletion: removes
    func completionNotification(id: ControllerIdentifier) {
        
        if id == self.mainControllerId {
            log.verbose("Main Controller finished: \(id.rawValue)")
            Coordinator.navigationController?.popViewController(animated: false)
        } else {
            log.verbose("Sub-Controller finished: \(id.rawValue)")
            deactivateSubController(id:id)
        }

    }
    
   
    // default activate. Checks the list of valid controllers and starts it if valid. Should be OK as-is
    func activateRequest(id: ControllerIdentifier) {

        guard self.validControllers.count > 0 else {
            log.error("Valid controller list is empty")
            return
        }
        guard self.validControllers.contains(id) else {
            log.error("Controller (\(id.rawValue) not valid in this state")
            return
        }
        
        //TODO: figure out if we need to start a new Coordinator to handle the Controller
        if self.coordinatorMap[id] != nil {
            // need to start a new Coordinator
            log.info("start new Coordinator for: \(id.rawValue)")
            self.startCoordinator(self.coordinatorMap[id]!)
            
        } else {
            
            // OK to just start the controller
            log.verbose("Attempting to start: \(id.rawValue)")
            let vc = ControllerFactory.getController(id)
            if vc != nil {
                
                if vc?.controllerType == .fullscreen { // full screen controller
                    activateController(id:id, vc: vc)
                } else { // sub-controller
                    activateSubController(id:id, vc:vc)
                }
                vc?.coordinator = self
                vc?.view.isHidden = false
            } else {
                log.error("Error creating controller: \(id.rawValue)")
            }
        }
    }
    
    
    // default requestUpdate: pass on to main controller
    func updateRequest(id: ControllerIdentifier) {
        DispatchQueue.main.async(execute: { self.mainController?.updateDisplays() })
    }
    
    
    // default help function
    func helpRequest() {
        // use the help file associated with the main controller id
        let title = (self.mainController?.getTitle())!
        let file = (self.mainController?.getHelpKey())!
        
        Coordinator.sharedInfo["helpTitle"] = title
        Coordinator.sharedInfo["helpFile"] = file
        
        self.activateRequest(id: .help)
        
        // NOTE: if there are multiple possible help files, then this func must be overridden in the Coordinator
    }
    
    // request to hide any subcontrollers that are active
    func hideSubcontrollersRequest() {
        if subControllers.count > 0 {
            if let id = subControllerStack.top {
                if let sc = subControllers[id]  {
                    sc.view.isHidden = true
                } else {
                    log.error("Could not get reference to subcontroller: \(id)")
                }
            }
        }
    }
    
    // request to show any subcontrollers that were previously hidden
    func showSubcontrollersRequest() {
        if subControllers.count > 0 {
            if let id = subControllerStack.top {
                if let sc = subControllers[id]  {
                    sc.view.isHidden = false
                } else {
                    log.error("Could not get reference to subcontroller: \(id)")
                }
            }
        }
    }
    
    // theme updated, tell the main controller and any subcontrollers
    func themeUpdatedNotification() {
        log.debug("Notifying Controller: \(self.mainControllerId.rawValue)")
        DispatchQueue.main.async(execute: { self.mainController?.updateTheme() })
        if self.subControllers.count > 0 {
            for id in self.subControllers.keys {
                if let vc = self.subControllers[id] {
                    log.debug("Notifying Subcontroller: \(id.rawValue)")
                   DispatchQueue.main.async(execute: { vc.updateTheme() })
                }
            }
        }
        // pass up the chain of command
        self.coordinator?.themeUpdatedNotification()
    }
    
    
    func startCoordinator(_ coordinator: CoordinatorIdentifier){
        if self.subCoordinators[coordinator] == nil {
            // not already running, so create
            self.subCoordinators[coordinator] = CoordinatorFactory.getCoordinator(coordinator)
        }
        if let subc = self.subCoordinators[coordinator] {
            subc.setCoordinator (self)
            subc.startRequest(completion: {  } )
        }
    }
    
    func activateController(id:ControllerIdentifier, vc:CoordinatedController?){
        if id == self.mainControllerId {
            self.mainController = vc
            self.mainControllerId = id
        }
        log.verbose("Pushing: \(id.rawValue)")
        vc?.id = id
        Coordinator.navigationController?.pushViewController(vc!, animated: false)
    }
    
    func activateSubController(id:ControllerIdentifier, vc:CoordinatedController?) {
        log.verbose("Adding sub-controller: \(id.rawValue)")
        if self.subControllers[id] != nil {
            log.warning("Sub-Controller being replaced: \(id.rawValue)")
        }
        self.subControllers[id] = vc
        vc?.id = id
        self.mainController?.add(vc!)
        vc?.view.isHidden = false
        
        // hide the currently active SubController
        if !subControllerStack.isEmpty {
            self.subControllers[subControllerStack.top!]?.view.isHidden = true
        }
        
        // Add to the stack
        subControllerStack.push(id)
    }
    
    func deactivateSubController(id:ControllerIdentifier) {
        log.verbose("Adding sub-controller: \(id.rawValue)")
        guard self.subControllers[id] != nil else {
            log.warning("Sub-Controller not active: \(id.rawValue)")
            return
        }

        log.verbose("Sub-Controller finished: \(id.rawValue)")
        subControllers[id]?.remove()
        subControllers[id] = nil
 
        // pop the current subcontroller
        if !subControllerStack.isEmpty {
            subControllerStack.pop()
        }
        
        // unhide the next one in the stack (if any)
        if !subControllerStack.isEmpty {
            self.subControllers[subControllerStack.top!]?.view.isHidden = false
        }
    }

}
