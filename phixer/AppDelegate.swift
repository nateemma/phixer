//
//  AppDelegate.swift
//  phixer
//
//  Created by Philip Price on 9/22/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import SwiftyBeaver

import Firebase
import GoogleMobileAds
import CoreData
import ChameleonFramework

let log = SwiftyBeaver.self

let themeColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)

//let filterManager:FilterManager = FilterManager.sharedInstance

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store 
         to fail.
         */
        let container = NSPersistentContainer(name: "")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                print("AppDelegate.loadPersistentStores() ERROR: \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // XcodeColors setup
        setenv("XcodeColors", "YES", 0); // Enables XcodeColors (you obviously have to install it too)

        // Swifty Beaver logging setup
        // add log destinations. at least one is needed!
        let console = ConsoleDestination()  // log to Xcode Console
        //let file = FileDestination()  // log to default swiftybeaver.log file
        //let cloud = SBPlatformDestination(appID: "foo", appSecret: "bar", encryptionKey: "123") // to cloud
        
        // use custom format and set console output to short time, log level & message
        //console.format = "$DHH:mm:ss$d $L $M"
        console.format = "$DHH:mm:ss.SSS$d $C$L $N.$F:$l - $M $c"
        

        // add the destinations to SwiftyBeaver
        log.addDestination(console)
        //log.addDestination(file)
        //log.addDestination(cloud)
        
        // set the global colour scheme
        window?.tintColor = themeColor
        Chameleon.setGlobalThemeUsingPrimaryColor(.flatBlack, with: .contrast)
        
        // set up Google banner ad framework
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
        //GADMobileAds.configure(withApplicationID: "ca-app-pub-3940256099942544~1458002511"); // Test ID, replace when ready
        GADMobileAds.configure(withApplicationID: Admob.appID)
        
        
        return true
    }

    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        FilterLibrary.commitChanges()
    }


}

