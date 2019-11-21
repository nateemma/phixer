
//
//  BlueTheme.swift
//
//
// Copyright (c) 2019 Phil Price
//

import UIKit
import Foundation


// Blue Theme
class BlueTheme: CustomTheme {

    
    // init values for this theme
    override init(){
        
        super.init()
        
        description = "Blue Theme"
        
        barStyle = .default
        
        navbarColor = UIColor.flatSkyBlue()
        navbarTintColor = UIColor.white
        navbarTextColor = UIColor.white
        mainColor = UIColor.white
        textColor = UIColor.flatBlueDark()
        backgroundColor = UIColor.white
        secondaryColor = UIColor.flatSkyBlueDark()
        titleColor = UIColor.flatSkyBlue()
        titleTextColor = UIColor.white
        subtitleTextColor = UIColor.white
        subtitleColor = UIColor.flatSkyBlue()
        buttonColor = UIColor.flatSkyBlueDark()
        borderColor = UIColor.flatBlueDark()
        highlightColor = UIColor.flatOrange()
        tintColor = UIColor.flatNavyBlueDark()
    }
    
    
    // override the default (system) font
    override func  getFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {

        var font: UIFont?
        
        // there is no generic API for retrieving a (non-system) font using both size and weight, so we have to explicitly code for it
        // Note that not all font families support all weights, so you have to look at the documentation
        // See http://iosfonts.com/ for fonts available by default with iOS
        switch weight {
        case .ultraLight:
            font = UIFont(name: "AvenirNextCondensed-UltraLight", size: fontSize)
        case .thin:
            font = UIFont(name: "AvenirNextCondensed-UltraLight", size: fontSize)
        case .light:
            font = UIFont(name: "AvenirNextCondensed-Regular", size: fontSize)
        case .regular:
            font = UIFont(name: "AvenirNextCondensed-Regular", size: fontSize)
        case .medium:
            font = UIFont(name: "AvenirNextCondensed-Medium", size: fontSize)
        case .semibold:
            font = UIFont(name: "AvenirNextCondensed-DemiBold", size: fontSize)
        case .bold:
            font = UIFont(name: "AvenirNextCondensed-Bold", size: fontSize)
        case .heavy:
            font = UIFont(name: "AvenirNextCondensed-Heavy", size: fontSize)
        case .black:
            font = UIFont(name: "AvenirNextCondensed-Bold", size: fontSize)
        default:
            font = UIFont(name: "AvenirNextCondensed-Regular", size: fontSize)
        }
        
        if font == nil {
            log.error("NIL font returned")
            return UIFont.systemFont(ofSize: fontSize, weight: weight)
        } else {
            return font!
        }
    }

}


