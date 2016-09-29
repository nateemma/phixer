//
//  SquareButton.swift
//  Philter
//
//  Created by Philip Price on 9/21/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//
import UIKit
import Neon


// Specialised button that is square with a centred image

class SquareButton: UIView {
    var button: UIButton! = UIButton(type: .custom)
    
    convenience init(bsize: CGFloat) {
        self.init(frame: CGRect(x:0, y:0, width:bsize, height:bsize))
        self.button.frame = CGRect(x:0, y:0, width:bsize, height:bsize)
        self.backgroundColor = UIColor.clear // transparent
        self.button.backgroundColor = UIColor.clear // transparent
        self.addSubview(button)
        
        
    }
    

    
    // (re-)set the image on a button
    func setImage(_ imageName: String){
        if let image = UIImage(named: imageName) {
            self.button.imageView?.contentMode = UIViewContentMode.scaleToFill
            self.button.setImage(image, for: UIControlState.normal)
        }
    }

    // passthrough for addTarget, just to avoid exposing the internal button
    func addTarget (_ target: Any?, action: Selector, for event: UIControlEvents){
        button.addTarget(target, action: action, for: event)
    }
    
    func setBackgroundColor(color: UIColor){
        button.backgroundColor = color
    }
}
