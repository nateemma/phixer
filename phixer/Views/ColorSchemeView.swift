//
//  ColorSchemeView.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit




class ColorSchemeView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    public var flatten:Bool = false {
        didSet {
            update()
        }
    }
    lazy var seedColor:UIColor = theme.buttonColor
    var requestedCount:Int = 6
    var colorScheme:ColorUtilities.ColorSchemeType = .complementary
    var colorList:[UIColor] = []
    var colorViews:[UIView] = []
    var numCollisions:Int = 0
    var enableFlatten:Bool = false
    var itemHeight:CGFloat = 32.0
    
    func removeSubviews(){
        //for view in self.subviews {
        for view in colorViews {
            view.removeFromSuperview()
        }
    }
    
    public func update(){
        if colorList.count > 0 {
            removeSubviews()
            self.displayColors(seed: self.seedColor, count: requestedCount, type: colorScheme)
        }
    }
    
    
    
    public func displayColors(seed:UIColor, count:Int, type:ColorUtilities.ColorSchemeType){
        var colors:[UIColor] = []
        var color:UIColor
        
        removeSubviews()
        colorList = []
        colorViews = []

        if count <= 0  {
            log.error("no components specified")
        } else {
            log.verbose("seed:\(seed.hexString) count:\(count) type:\(type)")
            // save values for later (e.g. resize, parameter change)
            seedColor = seed
            requestedCount = count
            colorScheme = type
            numCollisions = 0
            enableFlatten = flatten // can be changed for this run
            
            itemHeight = self.frame.height / CGFloat(count)
            
            // add the seed colour only if it is not included in the result (turn into func?)
            if (colorScheme != .monochromatic) && (colorScheme != .equidistant) {
                addColor(seed)
            }
            
            // generate the requested number of colours
            color = seed
            while (colorList.count<requestedCount){
                colors = []
                colors = ColorUtilities.getRelatedColors(color, count: count, type: type)
                for c in colors {
                    addColor(c)
                }
                // if we need more colours, set the ColorUtilities.HSB color to the analog of the current seed color for the next iteration
                if colorList.count<requestedCount {
                    color = ColorUtilities.analogous(color)[0]
                    addColor(color)
                }
            }
            
            // generate views from the colors
            
            if colorList.count > 0 {
                colorViews = []
                for c in colorList {
                    let v = makeColorView(c)
                    self.addSubview(v)
                    colorViews.append(v)
                }
                self.groupAndFill(group: .vertical, views: colorViews, padding: 2.0)
            }

        }
    }
    
    public func getScheme() -> [UIColor] {
        return colorList
    }
    
    
    
    private func addColor(_ color:UIColor){
        if (colorList.count<requestedCount){
            var c:UIColor

            if enableFlatten && (colorScheme != .monochromatic){
                c = color.flatten()
            } else {
                c = color
            }

            // check that colour is not already in the list (Flattening can cause the same colours to be selected)

            var found = false
            if colorList.count>0 {
                let hexc = c.hexString
                for cl in colorList {
                    let hc = cl.hexString
                    if (hexc == hc) {
                        found = true
                        //log.verbose("Ignoring duplicate colour (\(hexc)))")
                        numCollisions = numCollisions + 1
                        break
                    }
                }
            }

            if !found {
                //log.debug("Adding color: \(hexString(color)) \(ColorUtilities.HSBString(color)) \(RGBString(color))")
                colorList.append(c)
            }
            
            // collisions can be caused by flattening the colours. If too many are happening, disable it for this run
            if enableFlatten && (numCollisions > 10) {
                enableFlatten = false
                log.warning("Disabled Flattening of colours")
            }
        }
    }
    
    
    private func makeColorView(_ color:UIColor) -> UIView {
        var v:UIView
        var hexLabel:UILabel, rgbLabel:UILabel, hsbLabel:UILabel

        v = UIView()
        
        v.frame.size.width = self.width
        v.frame.size.height = self.height / CGFloat(requestedCount)
        v.backgroundColor = color

        log.debug("Colour: \(color.hexString) \(color.rgbString) \(color.hsbString)")
        
        // add text to show hex, rgb, hsb values
        hexLabel = UILabel()
        rgbLabel = UILabel()
        hsbLabel = UILabel()
        hexLabel.text = color.hexString
        rgbLabel.text = color.rgbString
        hsbLabel.text = color.hsbString
        for label in [hexLabel, rgbLabel, hsbLabel]{
            label.backgroundColor = UIColor.clear
            label.textAlignment = .center
            label.font = theme.getFont(ofSize: 12.0, weight: UIFont.Weight.thin)
            label.textColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat:false)
            label.shadowColor = nil
            v.addSubview(label)
        }
        hexLabel.font = theme.getFont(ofSize: 14.0, weight: UIFont.Weight.thin)

        // add constraints
        v.groupAndFill(group: .horizontal, views: [hexLabel, rgbLabel, hsbLabel], padding: 0)

        return v
    }

}

