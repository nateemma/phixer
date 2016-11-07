//
//  Admob.swift
//  FilterCam
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation

import GoogleMobileAds

// common point for getting Admob-related data

class Admob {
    static let testAppID:String = "ca-app-pub-3940256099942544~1458002511"
    static let testID:String      = "ca-app-pub-3940256099942544/2934735716" // Test ID
    
    static let filtercamAppID:String   = "ca-app-pub-0000000000000000~0000000000"
    static let filtercamID:String = "ca-app-pub-0000000000000000/0000000000" // the real ID for this app
    
    static var appID:String {  get { return Admob.testAppID } }// change to 'real' ID when ready
    
    static var unitID:String { get { return Admob.testID } }
    
    open static func startAds(view: GADBannerView, viewController:UIViewController){
        log.debug("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        view.adUnitID = Admob.unitID
        view.rootViewController = viewController
        view.load(GADRequest())
    }
}
