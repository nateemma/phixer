//
//  ColorSchemeView.swift
//  phixer
//
//  Created by Philip Price on 10/25/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit

public enum ColorSchemeType:String {
    case complementary = "Complementary"
    case analogous = "Analogous"
    case triadic = "Triadic"
    case tetradic = "Tetradic"
    case monochromatic = "Monochromatic"
    case splitComplimentary = "Split Complimentary"
    case equidistant = "Equidistant"
}



class ColorSchemeView: UIView {
    
    public var flatten:Bool = false {
        didSet {
            update()
        }
    }
    var seedColor:UIColor = UIColor.flatMint
    var requestedCount:Int = 6
    var colorScheme:ColorSchemeType = .complementary
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
    
    
    
    public func displayColors(seed:UIColor, count:Int, type:ColorSchemeType){
        var colors:[HSB] = []
        var hsb:HSB
        
        removeSubviews()
        colorList = []
        colorViews = []

        if count <= 0  {
            log.error("no components specified")
        } else {
            log.verbose("seed:\(RGBString(seed)) count:\(count) type:\(type)")
            // save values for later (e.g. resize, parameter change)
            seedColor = seed
            requestedCount = count
            colorScheme = type
            numCollisions = 0
            enableFlatten = flatten // can be changed for this run
            
            itemHeight = self.frame.height / CGFloat(count)
            
            // set up the initial seed colour
            hsb = colorToHsb(seed)
            // add the seed colour only if it is not included in the result (turn into func?)
            if (colorScheme != .monochromatic) && (colorScheme != .equidistant) {
                addColor(hsb)
            }
            
            // generate the requested number of colours
            while (colorList.count<requestedCount){
                colors = []
                colors = getRelatedColors(hsb, count: count, type: type)
                for c in colors {
                    addColor(c)
                }
                // if we need more colours, set the HSB color to the analog of the current seed color for the next iteration
                if colorList.count<requestedCount {
                    hsb = analogous(hsb)[0]
                    addColor(hsb)
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
    
    
    
    private func addColor(_ hsb:HSB){
        if (colorList.count<requestedCount){
            var c:UIColor

            let color = UIColor(hue: hsb.h, saturation: hsb.s, brightness: hsb.b, alpha: hsb.a)
            if enableFlatten && (colorScheme != .monochromatic){
                c = color.flatten()
            } else {
                c = color
            }

            // check that colour is not already in the list (Flattening can cause the same colours to be selected)

            var found = false
            if colorList.count>0 {
                let hexc = hexString(c)
                for cl in colorList {
                    let hc = hexString(cl)
                    if (hexc == hc) {
                        found = true
                        //log.verbose("Ignoring duplicate colour (\(hexc)))")
                        numCollisions = numCollisions + 1
                        break
                    }
                }
            }

            if !found {
                //log.debug("Adding color: \(hexString(color)) \(HSBString(color)) \(RGBString(color))")
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

        log.debug("Colour: \(hexString(color)) \(RGBString(color)) \(HSBString(color))")
        
        // add text to show hex, rgb, hsb values
        hexLabel = UILabel()
        rgbLabel = UILabel()
        hsbLabel = UILabel()
        hexLabel.text = hexString(color)
        rgbLabel.text = RGBString(color)
        hsbLabel.text = HSBString(color)
        for label in [hexLabel, rgbLabel, hsbLabel]{
            label.backgroundColor = UIColor.clear
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 12.0)
            label.textColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat:false)
            label.shadowColor = nil
            v.addSubview(label)
        }
        hexLabel.font = UIFont.boldSystemFont(ofSize: 14.0)

        // add constraints
        v.groupAndFill(group: .horizontal, views: [hexLabel, rgbLabel, hsbLabel], padding: 0)

        return v
    }
    
    
    //TEMP: move this stuff to it's own class:
    
    private struct HSB {
        var h: CGFloat = 0.5
        var s: CGFloat = 0.5
        var b: CGFloat = 0.5
        var a: CGFloat = 1.0
    }
    
    private func colorToHsb(_ color:UIColor) -> HSB{
        var hsb:HSB = HSB()
        var h:CGFloat=0.0, s:CGFloat=0.75, b:CGFloat=0.75, a:CGFloat=1.0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        hsb.h = h
        hsb.s = s
        hsb.b = b
        hsb.a = a
        if (hsb.s<0.01) || (hsb.b<0.01) || (hsb.a<0.01){
            log.warning("Suspicious conversion for color:\(color)")
        }
        return hsb
    }
    
    // convert colour to it's HEX string representation
    private func hexString(_ color:UIColor) -> String {
        var r:CGFloat=0.75, g:CGFloat=0.75, b:CGFloat=0.75, a:CGFloat=1.0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return "#\(String(format:"%02X",(IntVal(r,255))))\(String(format:"%02X",(IntVal(g,255))))\(String(format:"%02X",(IntVal(b,255))))"
    }
    
    // convert colour to it's RGB string representation
    private func RGBString(_ color:UIColor) -> String {
        var r:CGFloat=0.75, g:CGFloat=0.75, b:CGFloat=0.75, a:CGFloat=1.0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return "RGB:(\(IntVal(r,255)),\(IntVal(g,255)),\(IntVal(b,255)))"
    }
    
    // convert colour to it's HSB string representation
    private func HSBString(_ color:UIColor) -> String {
        var h:CGFloat=0.0, s:CGFloat=0.75, b:CGFloat=0.75, a:CGFloat=1.0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return "HSB:(\(IntVal(h,100)),\(IntVal(s,100)),\(IntVal(b,100)))"
    }

    // returns integer (0..range) version of color (0..1)
    private func IntVal(_ f:CGFloat, _ range:CGFloat) -> Int{
        return Int ((f*range).rounded())
    }
    // functions to return various relationships to the supplied colour
    
    private func getRelatedColors(_ hsb:HSB, count:Int, type:ColorSchemeType) -> [HSB] {
        switch (type){
        case .complementary:
            return complementary(hsb)
        case .analogous:
            return analogous(hsb)
        case .triadic:
            return triadic(hsb)
        case .tetradic:
            return tetradic(hsb)
        case .monochromatic:
            return monochromatic(hsb, count:count)
        case .splitComplimentary:
            return splitComplimentary(hsb)
        case .equidistant:
            return equidistant(hsb, count:count)
        }
    }
    
    private func complementary(_ hsb:HSB) -> [HSB]{
        var out:[HSB]
        out = []
        out.append(HSB(h: adjustHue(hsb.h, amount:0.5), s: hsb.s, b: hsb.b, a: hsb.a))
        //log.debug("Colors: \(out)")
        return out
    }
    
    private func splitComplimentary(_ hsb:HSB) -> [HSB]{
        var out:[HSB]
        out = []
        out.append(HSB(h: adjustHue(hsb.h, amount:150/360), s: hsb.s, b: hsb.b, a: hsb.a))
        out.append(HSB(h: adjustHue(hsb.h, amount:210/360), s: hsb.s, b: hsb.b, a: hsb.a))
        //log.debug("Colors: \(out)")
        return out
    }
    
    private func analogous(_ hsb:HSB) -> [HSB]{
        // 137.5 degrees ensures no duplicates, mostly a question of how close you want it to the original
        //let offset:CGFloat = (137.5/360.0)
        let offset:CGFloat = -1 / 12 // 30 degrees, from Stack Overflow
        //let offset:CGFloat = -1 / 13 // about 21 degrees, does not repeat to same colours

        var out:[HSB]
        out = []
        out.append(HSB(h: adjustHue(hsb.h, amount:offset), s: hsb.s, b: hsb.b, a: hsb.a))
        //out.append(HSB(h: adjustHue(hsb.h, amount:-offset), s: hsb.s, b: hsb.b, a: hsb.a))
        //log.debug("Colors: \(out)")
        return out
    }
    
    
    private func triadic(_ hsb:HSB) -> [HSB]{
        var out:[HSB]
        out = []
        out.append(HSB(h: adjustHue(hsb.h, amount:1/3), s: hsb.s, b: hsb.b, a: hsb.a))
        out.append(HSB(h: adjustHue(hsb.h, amount:2/3), s: hsb.s, b: hsb.b, a: hsb.a))
        //log.debug("Colors: \(out)")
        return out
    }
    
    
    private func tetradic(_ hsb:HSB) -> [HSB]{
        var out:[HSB]
        out = []
        out.append(HSB(h: adjustHue(hsb.h, amount:0.25), s: hsb.s, b: hsb.b, a: hsb.a))
        out.append(HSB(h: adjustHue(hsb.h, amount:0.5), s: hsb.s, b: hsb.b, a: hsb.a))
        out.append(HSB(h: adjustHue(hsb.h, amount:0.75), s: hsb.s, b: hsb.b, a: hsb.a))
        //log.debug("Colors: \(out)")
        return out
    }
    
    // note that the seed color *is* included in the list of colours
    private func monochromatic(_ hsb:HSB, count:Int) -> [HSB]{
        var out:[HSB]
        var b:CGFloat = 0.0
        out = []
        
        /***
        if (hsb.b>0.2)  && (hsb.b<0.8) {
            // Algorithm 1: space colours either side of supplied colour
            let mind = min((1.0-hsb.b), hsb.b)
            let interval = 2 * mind / CGFloat(count+2) // *2 because we go either side of the seed colour, +2 for margin
            var offset:CGFloat = hsb.b - CGFloat(count/2)*interval
            for _ in (0...(count-1)) {
                b = (hsb.b+offset).clamped(0.0, 1.0)
                out.append(HSB(h: hsb.h, s: hsb.s, b: b, a: hsb.a))
                offset = offset + interval
                //log.verbose("\(i): B:\(b)")
            }
        } else {
            // Algorithm 2: space colours evenly throughout the hue
            let interval = 1.0 / CGFloat(count+4)
            
            for i in 1...(count){
                b = (1.0 - CGFloat(i)*interval).clamped(0.0, 1.0)
                out.append(HSB(h: hsb.h, s: hsb.s, b: b, a: hsb.a))
            }
        }
         ***/
        
        // Algorithm 3. Spread evenly across 80% of the range, but make sure seed color is included
        let interval = 0.8 / CGFloat(count)
        let numAbove = Int((1.0 - hsb.b)/interval)
        b = hsb.b + CGFloat(numAbove) * interval
        for _ in 0...count {
            out.append(HSB(h: hsb.h, s: hsb.s, b: b, a: hsb.a))
            b = b - interval
        }
        
        //log.debug("Colors: \(out)")
        return out
    }
    
    
    // colours are spaced equally around the colour circle at the same brightness level
    // note that the seed color *is* included in the list of colours
    private func equidistant(_ hsb:HSB, count:Int) -> [HSB]{
        var out:[HSB]
        var h:CGFloat=0.75
        out = []
        
        let angle:CGFloat = 1.0 / CGFloat(count)
        // add the seed color then add colours equally spaced around the colour wheel
        out.append(hsb)
        h = hsb.h
        for _ in 1...count {
           // log.debug("[\(i)] h:\(h) angle:\(angle)")
            h = adjustHue(h, amount:angle)
            out.append(HSB(h: h, s: hsb.s, b: hsb.b, a: hsb.a))
        }

        return out
        
    }

    
    // adjust the hue value and perform any wrap calculations
    private func adjustHue(_ hue:CGFloat, amount:CGFloat) -> CGFloat{
        var h:CGFloat
        h = (hue + amount).truncatingRemainder(dividingBy: 1.0)
        if (h < 0){
            h = 1.0 + h
        }
        return h
    }
}

