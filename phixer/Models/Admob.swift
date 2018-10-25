//
//  Admob.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation

import GoogleMobileAds

// common point for getting Admob-related data

class Admob {
     // Test IDs
    static let testAppID:String = "ca-app-pub-3940256099942544~1458002511"
    static let testID:String      = "ca-app-pub-3940256099942544/2934735716"
    
    // the real IDs for this app
    static let phixerAppID:String   = "ca-app-pub-7657984226071633~8251277038"
    static let phixerID:String = "ca-app-pub-7657984226071633/3510086241"
    
    // change to 'real' IDs when ready
    static var appID:String {  get { return Admob.testAppID } }
    static var unitID:String { get { return Admob.testID } }
    
    public static func startAds(view: GADBannerView, viewController:UIViewController){
        log.debug("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        view.adUnitID = Admob.unitID
        view.rootViewController = viewController
        let request = GADRequest()
        request.testDevices = ["7243a3655f99acff2160255b107402e5"]
        view.load(request)
    }
}
