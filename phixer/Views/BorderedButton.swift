//
//  BorderedButton.swift
//  Philter
//
//  Created by Philip Price on 9/21/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//
import UIKit
import ChameleonFramework


// Button with

class BorderedButton: UIButton {
    var highlight:Bool = true
    public var useGradient:Bool = false
    public var color:UIColor = UIColor.flatMint {
        didSet {
            if useGradient {
                backgroundColor = UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:self.frame,
                                          andColors:[(color.darken(byPercentage: 40.0))!, (color.lighten(byPercentage: 40.0))!])
            } else {
                self.backgroundColor = color
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        customInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        customInit()
    }
    
    func customInit(){
        if useGradient {
            backgroundColor = UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:self.frame, andColors:[UIColor.black, UIColor.darkGray])
        } else {
            backgroundColor = color
        }
        setTitleColor(UIColor.white, for: .normal)
        titleLabel!.font = UIFont.boldSystemFont(ofSize: 16.0)
        contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        contentVerticalAlignment = UIControlContentVerticalAlignment.center
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = UIColor.flatGray.cgColor
    }
    
    // override the layout function to highlight the button if selected
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (highlight){
            if (self.state == .normal) {
                self.layer.borderColor = UIColor.clear.cgColor
            } else if (self.state == .highlighted) {
                self.layer.borderColor = UIColor.white.cgColor
            }
        }
    }
    
    // set whether or not to highlight on selection
    func highlightOnSelection(_ enable:Bool){
        highlight = enable
    }

}

extension UIColor {
    
    func lighter(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: abs(percentage) )
    }
    
    func darker(by percentage: CGFloat = 30.0) -> UIColor? {
        return self.adjust(by: -1 * abs(percentage) )
    }
    
    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                           green: min(green + percentage/100, 1.0),
                           blue: min(blue + percentage/100, 1.0),
                           alpha: alpha)
        } else {
            return nil
        }
    }
}
