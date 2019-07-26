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
    
    init(window: UIWindow?) {
        self.window = window
        
        Coordinator.navigationController = UINavigationController()

    }
    
    

    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    var initDone: Bool = false
    
    override func startRequest(completion: @escaping ()->()){
        
        if !initDone {
            initDone = true
            
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
            DispatchQueue.main.async(execute: { [weak self] in
                self?.prepareApp()
                self?.startMainController()
            })
        }
        
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
        //GADMobileAds.configure(withApplicationID: Admob.appID)
        // appID has been moved to info.plist
         GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    
    private func setupTheme() {
        
        // set the global colour scheme - needed before assigning the Navigation Controller since that uses the current theme
        ThemeManager.applyTheme(key: ThemeManager.getSavedTheme())
        let theme = ThemeManager.currentTheme()
        
        Coordinator.navigationController?.navigationBar.barStyle = .blackTranslucent
        Coordinator.navigationController?.navigationBar.isTranslucent = true
        Coordinator.navigationController?.view.backgroundColor = theme.titleColor
        Coordinator.navigationController?.navigationBar.tintColor = theme.tintColor

    }
    
    
    private func setupConfig() {
/***
        // Create an instance of FilterManager. This will take care of reading the configuration file etc.
        DispatchQueue.main.async(execute: {
            Coordinator.filterManager = FilterManager.sharedInstance
        })
***/
        setupFrames()
        
    }
    
    
    private func setupCoordinator() {
        
        /*** old version (start at main controller
 
        self.mainControllerId = .mainMenu
        
        // define the list of valid Controllers
        self.validControllers = [ .mainMenu, .choosePhoto, .edit, .browseFilters, .browseStyleTransfer, .settings, .help ]
        
        // map controllers to their associated coordinators
        self.coordinatorMap [ControllerIdentifier.choosePhoto] = CoordinatorIdentifier.choosePhoto
        self.coordinatorMap [ControllerIdentifier.edit] = CoordinatorIdentifier.edit
        self.coordinatorMap [ControllerIdentifier.browseFilters] = CoordinatorIdentifier.browseFilters
        self.coordinatorMap [ControllerIdentifier.browseStyleTransfer] = CoordinatorIdentifier.browseStyleTransfer
        self.coordinatorMap [ControllerIdentifier.settings] = CoordinatorIdentifier.settings
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help

         ***/
        
        // new version, start at "Choose Photo"
        self.mainControllerId = .choosePhoto
        self.validControllers = [.choosePhoto, .mainMenu ]
        
        self.coordinatorMap = [:]
        self.coordinatorMap [ControllerIdentifier.mainMenu] = CoordinatorIdentifier.mainMenu
    }


    // set up frames for the various types of controllers:
    private func setupFrames() {

        let w = UIScreen.main.bounds.size.width
        let h = UIScreen.main.bounds.size.height
        //let toolSize = w - UISettings.menuHeight / 2.0
        let toolSize = w - 16
        
        //let fullFrame:CGRect = CGRect(x: 0, y: UISettings.topBarHeight, width: w, height: h-UISettings.topBarHeight)
        let fullFrame:CGRect = CGRect(x: 0, y: 0, width: w, height: h)
        let menuFrame:CGRect = CGRect(x: 0, y: h-(UISettings.titleHeight+UISettings.menuHeight), width: w, height: (UISettings.titleHeight+UISettings.menuHeight))
        //let toolFrame:CGRect = CGRect(x: (w-toolSize)/2.0, y: UISettings.menuHeight, width: toolSize, height: toolSize)
        let toolFrame:CGRect = CGRect(x: 0.0, y: h-w, width: w, height: w) // fill bottom portion of screen

        ControllerFactory.setFrame(.fullscreen, frame: fullFrame)
        ControllerFactory.setFrame(.menu, frame: menuFrame)
        ControllerFactory.setFrame(.paneltool, frame: toolFrame)
        ControllerFactory.setFrame(.fulltool, frame: fullFrame)

        log.debug("screen: (\(w),\(h)), top bar h: \(UISettings.topBarHeight)")
    }

    
    /////////////////////////////
    // MARK:  Main Logic
    /////////////////////////////

    private func startMainController() {
        
        // a little different since nothing is running yet. Set the top-level Menu as the root ViewController
        
        /*** old version (start at main controller
        self.mainController = MainMenuController()
        self.mainController?.coordinator = self
        self.mainControllerTag = (self.mainController?.getTag())!
        self.mainControllerId = .mainMenu
        //DispatchQueue.main.async(execute: {
            Coordinator.navigationController?.setViewControllers([self.mainController!], animated: false)
       //})
         ***/
        self.mainController = ControllerFactory.getController(self.mainControllerId)
        self.mainController?.coordinator = self
        self.mainControllerTag = (self.mainController?.getTag())!
        Coordinator.navigationController?.setViewControllers([self.mainController!], animated: false)

        // Create an instance of FilterManager (in a different queue entry). This will take care of reading the configuration file etc.
        //DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000)) {
        DispatchQueue.global(qos: .utility).async() {
            [weak self] in
            FilterManager.checkSetup()
            Coordinator.filterManager = FilterManager.sharedInstance
        }

       // self.activate(self.mainControllerId)
//        if self.mainController != nil {
//            Coordinator.navigationController = UINavigationController(rootViewController: self.mainController!)
//            //window?.rootViewController = self.mainController
//        }
    }
}
