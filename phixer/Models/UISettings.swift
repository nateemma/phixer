//
//  UISettings.swift
//  phixer
//
//  Created by Philip Price on 9/26/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit

// static class with methods used for setting up and controlling UI appearance and behaviour

class UISettings{
    
    static var isLandscape : Bool = false
    
    static var screenSize : CGRect = CGRect.zero
    static var displayWidth : CGFloat = 0.0
    static var displayHeight : CGFloat = 0.0
    static let bannerHeight : CGFloat = 64.0
    static let buttonSize : CGFloat = 48.0

    
    
    // Banner/Navigation View (title)
    static let statusBarOffset : CGFloat = 2.0
    static var showAds:Bool = true
}
