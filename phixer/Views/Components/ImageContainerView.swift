//
//  ImageView.swift
//  Philter
//
//  Created by Philip Price on 9/17/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//
import UIKit
import Neon


// View that contains an image with a label underneath

class ImageContainerView: UIView {
    
    var theme = ThemeManager.currentTheme()
    
    var imageView : UIImageView = UIImageView()
    var label : UILabel = UILabel()
    var addBorder:Bool = true
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
        self.backgroundColor = theme.backgroundColor
        if addBorder {
            enableBorder()
        } else {
            disableBorder()
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        
        label.textAlignment = .center
        label.textColor = theme.textColor
        //label.font = theme.getFont(ofSize: 12.0)
        label.font = theme.getFont(ofSize: 10.0, weight: UIFont.Weight.thin)
        self.addSubview(label)
    }
    
    public func enableBorder(){
        self.layer.cornerRadius = 2.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = theme.borderColor.withAlphaComponent(0.5).cgColor
        self.clipsToBounds = true
    }
    
    public func disableBorder(){
        self.layer.cornerRadius = 0.0
        self.layer.borderWidth = 0.0
        self.layer.borderColor = UIColor.clear.cgColor
        self.clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height * 0.7)
        label.alignAndFill(align: .underCentered, relativeTo: imageView, padding: 0)
    }
    

}

