//
//  SquareButton.swift
//  Philter
//
//  Created by Philip Price on 9/21/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//
import UIKit
import Neon


// Specialised button that is square with a centred image and no text

class SquareButton: UIView {
    
    var theme = ThemeManager.currentTheme()
    
    var button: UIButton! = UIButton(type: .custom)
    var highlight:Bool = false
    
    convenience init(bsize: CGFloat) {
        self.init(frame: CGRect(x:0, y:0, width:bsize, height:bsize))
        self.button.frame = CGRect(x:0, y:0, width:bsize, height:bsize)
        self.backgroundColor = UIColor.clear // transparent
        self.button.backgroundColor = UIColor.clear // transparent
        //self.isUserInteractionEnabled = false // don't handle touches in the containing view
        
        self.button.layer.cornerRadius = 5
        self.button.layer.borderWidth = 2
        self.button.layer.borderColor = UIColor.clear.cgColor
        
        self.addSubview(button)
    }
    
    
    // override the layout function to highlight the button if selected
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (highlight){
            if (self.button.state == .normal) {
                self.button.layer.borderColor = UIColor.clear.cgColor
            } else if (self.button.state == .highlighted) {
                self.button.layer.borderColor = theme.titleTextColor.cgColor
            }
        }
    }
    
    // set whether or not to highlight on selection
    func highlightOnSelection(_ enable:Bool){
        highlight = enable
    }
    
    // (re-)set the image on a button using a project asset
    func setImageAsset(_ assetName: String){
        var image:UIImage?
        
        image = UIImage(named: assetName)
        
        if (image == nil) {
            log.warning("WARN: unable to find asset (\(assetName)")
            image = UIImage(named: "ic_unknown")
        }
        
        self.button.imageView?.contentMode = UIViewContentMode.scaleToFill
        self.button.setImage(image, for: UIControlState.normal)
    }
    
    // set the image based on any UIImage (e.g. from Camera Roll)
    func setImage(_ image: UIImage){
        self.button.imageView?.contentMode = UIViewContentMode.scaleToFill
        self.button.setImage(image, for: UIControlState.normal)
    }
    
    // passthrough for addTarget, just to avoid exposing the internal button
    func addTarget (_ target: Any?, action: Selector, for event: UIControlEvents){
        self.button.isUserInteractionEnabled = true
        self.button.addTarget(target, action: action, for: event)
    }
    
    func setColor(_ color: UIColor){
        self.button.backgroundColor = color
    }
}
