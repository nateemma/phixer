//
//  SimpleCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// class that implements the simple case of a single Controller. The ID can be passed to the constructor

class SimpleCoordinator: Coordinator {
   
    
    // set the ID of the main controller
    func setMainController(_ controller: ControllerIdentifier) {
        self.mainControllerId = controller
    }
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    override func selectFilter(key: String) {
        log.error("Not supported by this Coordnator")
        // TODO: Set it anyway?
    }
    
    override func nextFilter() -> String {
        log.error("Not supported by this Coordnator")
        return (Coordinator.filterManager?.getCurrentFilterKey())!
    }
    
    override func previousFilter() -> String {
        log.error("Not supported by this Coordnator")
        return (Coordinator.filterManager?.getCurrentFilterKey())!
    }
    
    
    override func start(completion: @escaping ()->()){
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: type(of: self))): \(self.mainControllerId.rawValue) ==========\n")
        
        // reset controller/coordinator vars
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.mainController = nil
        self.subControllers = [:]
        self.validControllers = [self.mainControllerId]
        
         self.activate(self.mainControllerId)
        
    }


}
