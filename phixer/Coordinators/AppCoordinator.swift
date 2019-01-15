//
//  AppCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// class that implements the coordination for the main (top-level) App
// Note that this Coordinator is different from others in that it interacts with the ppDelegate to set up the root view controller etc.

class AppCoordinator: Coordinator {
   
    
    
    /////////////////////////////
    // MARK:  Interaction with AppDelegate. Do not put this in any other Coodinator classes
    /////////////////////////////

    var window: UIWindow? = nil
    
    lazy var rootViewController: UINavigationController = {
        return UINavigationController(rootViewController: UIViewController())
    }()
    
    
    init(window: UIWindow?) {
        Coordinator.navigationController = UINavigationController(rootViewController: UIViewController())
        self.window = window
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
    
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    override func start(completion: @escaping ()->()){
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: type(of: self))) ==========\n")
        
        guard let window = window else {
            return
        }
        
        window.rootViewController = Coordinator.navigationController
        window.makeKeyAndVisible()
        
        // reset controller/coordinator vars
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.mainController = nil
        self.subControllers = [:]
        self.validControllers = []

        //TODO: display transition screen while the App is being prepared???
        
        prepareApp()
        
        startMainController()
        
    }
    
    /////////////////////////////
    // MARK:  Initial Setup
    /////////////////////////////
 
    func prepareApp(){
        
        setupAds()
        setupTheme()
        setupConfig()
        setupCoordinator()
    }

    private func setupAds() {
        // set up Google banner ad framework. Use the Firebase library to configure APIs
        FirebaseApp.configure()
        
        //GADMobileAds.configure(withApplicationID: "ca-app-pub-3940256099942544~1458002511"); // Test ID, replace when ready
        GADMobileAds.configure(withApplicationID: Admob.appID)
    }
    
     private func setupTheme() {

        // set the global colour scheme
        ThemeManager.applyTheme(key: ThemeManager.getSavedTheme())
    }
    
    private func setupConfig() {
        // Create an instance of Filteranager. This will take care of reading the configuration file etc.
        Coordinator.filterManager = FilterManager.sharedInstance
        
        setupFrames()
        
    }
    
    private func setupCoordinator() {
        
        self.mainControllerId = .home
        
        // define the list of valid Controllers
        self.validControllers = [ .home, .edit, .browse, .styleTransfer, .settings ]
        
        // map controllers to their associated coordinators
        self.coordinatorMap [ControllerIdentifier.edit] = CoordinatorIdentifier.edit
        self.coordinatorMap [ControllerIdentifier.browse] = CoordinatorIdentifier.browse
        self.coordinatorMap [ControllerIdentifier.styleTransfer] = CoordinatorIdentifier.styleTransfer
        self.coordinatorMap [ControllerIdentifier.settings] = CoordinatorIdentifier.settings

    }


    // set up frames for the various types of controllers:
    private func setupFrames() {

        let w = UIScreen.main.bounds.size.width
        let h = UIScreen.main.bounds.size.width
        let topBarHeight = UIApplication.shared.statusBarFrame.size.height +
            (Coordinator.navigationController?.navigationBar.frame.height ?? 0.0)
        let menuHeight:CGFloat = 88.0
        
        let fullFrame:CGRect = CGRect(x: 0, y: topBarHeight, width: w, height: h)
        let menuFrame:CGRect = CGRect(x: 0, y: h-menuHeight, width: w, height: h)
        let toolFrame:CGRect = CGRect(x: menuHeight/2.0, y: menuHeight, width: w, height: h)
        
        ControllerFactory.setFrame(.fullscreen, frame: fullFrame)
        ControllerFactory.setFrame(.menu, frame: menuFrame)
        ControllerFactory.setFrame(.tool, frame: toolFrame)

    }

    
    /////////////////////////////
    // MARK:  Main Logic
    /////////////////////////////

    private func startMainController() {
        
        self.activate(self.mainControllerId)
    }
}
