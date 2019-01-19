//
//  DefaultControllerMenuView.swift
//  phixer
//
//  Created by Philip Price on 1/17/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon

// This class implements the default menu drop down display for CoordinatedControllers. It has to be a separate class because of the way extensions/delegates are handled in inheritance structures



protocol DefaultControllerMenuDelegate: class{
    func defaultMenuItemSelected(key:String)
}

class DefaultControllerMenuView: UIView {
    
    
    var theme = ThemeManager.currentTheme()
    
    weak var delegate: DefaultControllerMenuDelegate? = nil
    
    let bannerHeight : CGFloat = 64.0

    
    ////////////////////
    // Default Menu - override func handleMenu() in the Controller subclass to provide a differet set of options
    ////////////////////
    
    private var defaultMenuItems:[Adornment] = [ ]
    private var menuView:AdornmentView! = AdornmentView()
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        theme = ThemeManager.currentTheme()
        self.backgroundColor = theme.backgroundColor
        
        self.frame.size.height = CGFloat(bannerHeight)
        self.frame.size.width = self.frame.size.width
        
        menuView.frame = self.frame
        self.addSubview(menuView)
        
        //let topBarHeight = UIApplication.shared.statusBarFrame.size.height + (Coordinator.navigationController?.navigationBar.frame.height ?? 0.0)
        let topBarHeight:CGFloat = 0.0

        self.anchorAndFillEdge(.top, xPad: 0, yPad: topBarHeight, otherSize: self.frame.size.height)
        
        // build the list of adornments
        self.defaultMenuItems = []
        self.defaultMenuItems.append (Adornment(key: "help", text: "help", icon: "ic_help", view: nil, isHidden: false))
        
        // populate the menu
        menuView.addAdornments(self.defaultMenuItems)
        menuView.delegate = self
        self.isHidden = true // start off as hidden
        
        // OK, with only one item, make the whole view touchable
        self.isUserInteractionEnabled = true
        
    }
    
    // handler - just pass on to the delegate
    fileprivate func handleDefaultMenuSelection(key: String){
            log.debug("key: \(key)")
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.defaultMenuItemSelected(key: key)
            })
    }
    
    
    //////////////////////////////////////////
    // MARK: - Touch handling
    //////////////////////////////////////////
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.defaultMenuItemSelected(key: "help")
            })
        }
    }
    
    


}




// Adornment delegate

extension DefaultControllerMenuView: AdornmentDelegate {
    @objc func adornmentItemSelected(key: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.handleDefaultMenuSelection(key: key)
        })
    }
}
