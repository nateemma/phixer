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
    var subControllers: [ControllerIdentifier:CoordinatedController] = [:]
    
    // completion handler for when this coordinator has finished (set by parent)
    var completionHandler:(()->())? = nil

    // reference to the FilterManager
    static var filterManager: FilterManager? = nil

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
            self.mainController?.selectFilter(key: key)
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
        
        // TODO: ask current subcontroller
        // Temp HACK: ask any csub-controller that is currently not hidden. May get mulitple responses!
        if subControllers.count > 0 {
            for k in self.subControllers.keys {
                if self.subControllers[k]?.view.isHidden == false {
                    let sc = subControllers[k] as? SubControllerDelegate
                    if sc != nil {
                        sc?.previousItem()
                    } else {
                        log.error("Could not get reference to subcontroller: \(k)")
                    }
                }
            }
        } else {
            log.error("Base class. Unable to route request")
         }
    }
    
    
    
    // move to the previous item, whatever that is (can be nothing)
    func previousItemRequest() {
        
        // TODO: ask current subcontroller
        // Temp HACK: ask any csub-controller that is currently not hidden. May get mulitple responses!
        if subControllers.count > 0 {
            for k in self.subControllers.keys {
                if self.subControllers[k]?.view.isHidden == false {
                    let sc = subControllers[k] as? SubControllerDelegate
                    if sc != nil {
                        sc?.previousItem()
                    } else {
                        log.error("Could not get reference to subcontroller: \(k)")
                    }
                }
            }
        } else {
            log.error("Base class. Unable to route request")
        }
    }

    

    // default notifyCompletion: removes
    func completionNotification(id: ControllerIdentifier) {
        
        if id == self.mainControllerId {
            log.verbose("Main Controller finished: \(id.rawValue)")
            Coordinator.navigationController?.popViewController(animated: true)
        } else {
            if subControllers[id] != nil {
                log.verbose("Sub-Controller finished: \(id.rawValue)")
                subControllers[id]?.remove()
                subControllers[id] = nil
                // TODO: restore previous sub-controller?
            } else {
                log.error("Unkown Sub-Controller: \(id.rawValue)")
            }
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
                    if id == self.mainControllerId {
                        self.mainController = vc
                        self.mainControllerId = id
                    }
                    log.verbose("Pushing: \(id.rawValue)")
                    Coordinator.navigationController?.pushViewController(vc!, animated: true)
                } else { // sub-controller
                    log.verbose("Adding sub-cntroller: \(id.rawValue)")
                    if self.subControllers[id] != nil {
                        log.warning("Sub-Controller being replaced: \(id.rawValue)")
                    }
                    self.subControllers[id] = vc
                    self.mainController?.add(vc!)
                    vc?.view.isHidden = false
                    
                    // TODO: maintain stack of sub-controllers
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
        self.mainController?.updateDisplays()
    }
    // default help function
    func helpRequest() {
        // use the help file associated with the main controller id
        let vc = ControllerFactory.getController(.help) as? HTMLViewController
        vc?.setTitle("Help: \((self.mainController?.getTitle())!)")
        vc?.loadFile(name: (self.mainController?.getHelpKey())!)
        
        // NOTE: if there are multiple possible help files, then this func must be overridden in the Coordinator
    }
    
    private var hideList:[ControllerIdentifier] = []
    
    // request to hide any subcontrollers that are active
    func hideSubcontrollersRequest() {
        if self.subControllers.count > 0 {
            for k in self.subControllers.keys {
                if self.subControllers[k]?.view.isHidden == false {
                    self.subControllers[k]?.view.isHidden = true
                    self.hideList.append(k)
                }
            }
        }
    }
    
    // request to show any subcontrollers that were previously hidden
    func showSubcontrollersRequest() {
        for k in self.hideList {
            self.subControllers[k]?.view.isHidden = false
        }
        self.hideList = []
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

}
