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

    //var window: UIWindow? = nil
    
    //init(window: UIWindow?) {
    override init() {
        //Coordinator.window = window
        
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
            
            guard let window = Coordinator.window else {
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
            
            prepareApp()
            startMainController()

        }
        
    }
    

    
    
    /////////////////////////////
    // MARK:  Initial Setup
    /////////////////////////////
 
    func prepareApp(){
        
        //setupAds()
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
        let key = ThemeManager.getSavedTheme()
        ThemeManager.applyTheme(key: key)
        let theme = ThemeManager.currentTheme()
        
        ThemeManager.applyTheme(key: key)
        
        // translucent removed in iOS13
        //Coordinator.navigationController?.navigationBar.barStyle = .blackTranslucent
        //Coordinator.navigationController?.navigationBar.isTranslucent = true
        
        Coordinator.navigationController?.view.backgroundColor = theme.navbarColor
        Coordinator.navigationController?.navigationBar.barStyle = .default
        Coordinator.navigationController?.navigationBar.isTranslucent = false
        Coordinator.navigationController?.navigationBar.backgroundColor = theme.navbarColor
        Coordinator.navigationController?.navigationBar.tintColor = theme.navbarTintColor
        Coordinator.navigationController?.navigationBar.barTintColor = theme.navbarColor

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
        //let menuFrame:CGRect = CGRect(x: 0, y: h-(UISettings.titleHeight+UISettings.menuHeight), width: w, height: (UISettings.titleHeight+UISettings.menuHeight))
        let menuFrame:CGRect = CGRect(x: 0, y: h-(UISettings.titleHeight+UISettings.menuHeight), width: w, height: (UISettings.menuHeight))
        //let toolFrame:CGRect = CGRect(x: (w-toolSize)/2.0, y: UISettings.menuHeight, width: toolSize, height: toolSize)
        let toolFrame:CGRect = CGRect(x: 0.0, y: h-w, width: w, height: w) // fill bottom portion of screen

        ControllerFactory.setFrame(.fullscreen, frame: fullFrame)
        ControllerFactory.setFrame(.menu, frame: menuFrame)
        ControllerFactory.setFrame(.paneltool, frame: toolFrame)
        ControllerFactory.setFrame(.fulltool, frame: fullFrame)

        //log.debug("screen: (\(w),\(h)), top bar h: \(UISettings.topBarHeight)")
    }

    
    /////////////////////////////
    // MARK:  Main Logic
    /////////////////////////////

    private func startMainController() {
        
        self.mainController = ControllerFactory.getController(self.mainControllerId)
        self.mainController?.coordinator = self
        self.mainControllerTag = (self.mainController?.getTag())!
        Coordinator.navigationController?.setViewControllers([self.mainController!], animated: false)

        /*** done elsewhere
        // Create an instance of FilterManager (in a different queue entry). This will take care of reading the configuration file etc.
        //DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2000)) {
        DispatchQueue.global(qos: .utility).async() {
            [weak self] in
            FilterManager.checkSetup()
            Coordinator.filterManager = FilterManager.sharedInstance
        }
         ***/

    }
}
