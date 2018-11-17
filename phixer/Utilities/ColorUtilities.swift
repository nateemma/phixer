//
//  ColorUtilities.swift
//  phixer
//
//  Created by Philip Price on 11/15/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit


// class that provides utilities for dealing with colours
// Typically 2 variants: normal colors (UIColor) and a Hue/Saturation/Brightness (UIColor) version, which is sometimes easier

class ColorUtilities {
    
    public enum ColorSchemeType:String {
        case complementary = "Complementary"
        case analogous = "Analogous"
        case triadic = "Triadic"
        case tetradic = "Tetradic"
        case monochromatic = "Monochromatic"
        case splitComplimentary = "Split Complimentary"
        case equidistant = "Equidistant"
    }

    //=================================
    
    // functions to return various relationships to the supplied colour
    
    public static func getRelatedColors(_ color:UIColor, count:Int, type:ColorSchemeType) -> [UIColor] {
        switch (type){
        case .complementary:
            return complementary(color)
        case .analogous:
            return analogous(color)
        case .triadic:
            return triadic(color)
        case .tetradic:
            return tetradic(color)
        case .monochromatic:
            return monochromatic(color, count:count)
        case .splitComplimentary:
            return splitComplimentary(color)
        case .equidistant:
            return equidistant(color, count:count)
        }
    }
    
    public static func complementary(_ color:UIColor) -> [UIColor]{
        var out:[UIColor]
        out = []
        out.append(adjustHue(color, amount:0.5))
        //log.debug("Colors: \(out)")
        return out
    }
    
    public static func splitComplimentary(_ color:UIColor) -> [UIColor]{
        var out:[UIColor]
        out = []
        out.append(adjustHue(color, amount:150/360))
        out.append(adjustHue(color, amount:210/360))
        //log.debug("Colors: \(out)")
        return out
    }
    
    public static func analogous(_ color:UIColor) -> [UIColor]{
        // 137.5 degrees ensures no duplicates, mostly a question of how close you want it to the original
        //let offset:CGFloat = (137.5/360.0)
        let offset:CGFloat = -1 / 12 // 30 degrees, from Stack Overflow
        //let offset:CGFloat = -1 / 13 // about 21 degrees, does not repeat to same colours
        
        var out:[UIColor]
        out = []
        out.append(adjustHue(color, amount:offset))
        //out.append(adjustHue(color, amount:-offset))
        //log.debug("Colors: \(out)")
        return out
    }
    
    
    public static func triadic(_ color:UIColor) -> [UIColor]{
        var out:[UIColor]
        out = []
        out.append(adjustHue(color, amount:1/3))
        out.append(adjustHue(color, amount:2/3))
        //log.debug("Colors: \(out)")
        return out
    }
    
    
    public static func tetradic(_ color:UIColor) -> [UIColor]{
        var out:[UIColor]
        out = []
        out.append(adjustHue(color, amount:0.25))
        out.append(adjustHue(color, amount:0.5))
        out.append(adjustHue(color, amount:0.75))
        //log.debug("Colors: \(out)")
        return out
    }
    
    // note that the seed color *is* included in the list of colours
    public static func monochromatic(_ color:UIColor, count:Int) -> [UIColor]{
        var out:[UIColor]
        var adjust:CGFloat = 0.0
        out = []
        
        var h:CGFloat=0.0, s:CGFloat=0.75, b:CGFloat=0.75, a:CGFloat=1.0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        // Spread evenly across 80% of the range, but make sure seed color is included
        let interval = 0.8 / CGFloat(count)
        let numAbove = Int((1.0 - b)/interval)
        adjust = CGFloat(numAbove) * interval
        for _ in 0...count {
            out.append(adjustBrightness(color, amount: adjust))
            adjust = adjust - interval
        }
        
        //log.debug("Colors: \(out)")
        return out
    }
    
    
    // colours are spaced equally around the colour circle at the same brightness level
    // note that the seed color *is* included in the list of colours
    public static func equidistant(_ color:UIColor, count:Int) -> [UIColor]{
        var out:[UIColor]
        var c:UIColor
        out = []
        
        let angle:CGFloat = 1.0 / CGFloat(count)
        // add the seed color then add colours equally spaced around the colour wheel
        out.append(color)
        c = color
        for _ in 1...count {
            // log.debug("[\(i)] h:\(h) angle:\(angle)")
            c = adjustHue(c, amount:angle)
            out.append(c)
        }
        
        return out
        
    }
    
    
    // adjust the hue value and perform any wrap calculations
    public static func adjustHue(_ color:UIColor, amount:CGFloat) -> UIColor{
        var h:CGFloat=0.0, s:CGFloat=0.75, b:CGFloat=0.75, a:CGFloat=1.0
        var newh:CGFloat=0.0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        newh = (h + amount).truncatingRemainder(dividingBy: 1.0)
        if (newh < 0){
            newh = 1.0 + newh
        }
        return UIColor(hue:newh, saturation:s, brightness:b, alpha:a)
    }
    
    
    // adjust the saturation value by the amount specifies. Result is clampoed to 0..1
    public static func adjustSaturation(_ color:UIColor, amount:CGFloat) -> UIColor{
        var h:CGFloat=0.0, s:CGFloat=0.75, b:CGFloat=0.75, a:CGFloat=1.0
        var news:CGFloat=0.0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        news = ((s + amount).truncatingRemainder(dividingBy: 1.0)).clamped(0.0, 1.0)
        return UIColor(hue:h, saturation:news, brightness:b, alpha:a)
    }
    
    
    // adjust the brightness value by the amount specifies. Result is clampoed to 0..1
    public static func adjustBrightness(_ color:UIColor, amount:CGFloat) -> UIColor{
        var h:CGFloat=0.0, s:CGFloat=0.75, b:CGFloat=0.75, a:CGFloat=1.0
        var newb:CGFloat=0.0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        newb = ((b + amount).truncatingRemainder(dividingBy: 1.0)).clamped(0.0, 1.0)
        return UIColor(hue:h, saturation:s, brightness:newb, alpha:a)
    }
}
