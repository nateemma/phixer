//
//  swift
//  phixer
//
//  Created by Philip Price on 9/26/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit

// static class with methods used for setting up and controlling UI appearance and behaviour

class UISettings{
    
    static var isLandscape : Bool {  return ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight)) }
    static var isPortrait: Bool { return !isLandscape }
    
    static var screenSize : CGSize { return UIScreen.main.bounds.size }
    static var screenWidth : CGFloat { return UIScreen.main.bounds.size.width }
    static var screenHeight : CGFloat  { return UIScreen.main.bounds.size.height }
    static var screenScale:CGFloat { return UIScreen.main.scale }
    static var screenResolution:CGSize = CGSize(width: (UIScreen.main.bounds.size.width * UIScreen.main.scale), height: (UIScreen.main.bounds.size.height * UIScreen.main.scale))
    
    static var topBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height + (Coordinator.navigationController?.navigationBar.frame.height ?? 0.0)
    }
    static let panelHeight : CGFloat = 64.0
    static let menuHeight : CGFloat = 88.0
    static let buttonSide : CGFloat = 48.0
    static let buttonSize : CGSize = CGSize(width: 48.0, height: 48.0)

    static let statusBarOffset : CGFloat = 0.0
    
    static var showAds:Bool = true
    static var AdViewHeight:CGFloat { return panelHeight }
    

}
