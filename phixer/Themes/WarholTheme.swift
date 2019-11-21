
//
//  WarholTheme.swift
//
//
// Copyright (c) 2019 Phil Price
//

import UIKit
import Foundation


// Warhol Theme
class WarholTheme: CustomTheme {

    // Warhol colours
    let warholRed = UIColor(hex: "F23A3A")
    let warholGreen = UIColor(hex: "77CC62")
    let warholBlue = UIColor(hex: "5280C7")
    let warholYellow = UIColor(hex: "F0D848")
    let warholPink = UIColor(hex: "FA8C82")

    // init values for this theme
    override init(){
        
        super.init()
        
        description = "Andy Warhol"
        
        barStyle = .default
        
        navbarColor = warholGreen
        navbarTintColor = warholBlue
        navbarTextColor = UIColor.black
        mainColor = warholPink
        textColor = UIColor.black
        backgroundColor = warholPink
        secondaryColor = warholBlue
        titleColor = warholRed
        titleTextColor = UIColor.black
        subtitleTextColor = UIColor.black
        subtitleColor = warholYellow
        buttonColor = warholPink
        borderColor = warholGreen
        highlightColor = warholYellow
        tintColor = warholBlue
    }
    
    
    // override the default (system) font
    override func  getFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {

        var font: UIFont?
        
        // there is no generic API for retrieving a (non-system) font using both size and weight, so we have to explicitly code for it
        // Note that not all font families support all weights, so you have to look at the documentation
        // See http://iosfonts.com/ for fonts available by default with iOS
        switch weight {
        case .ultraLight:
            font = UIFont(name: "AmericanTypewriter-CondensedLight", size: fontSize)
        case .thin:
            font = UIFont(name: "AmericanTypewriter-CondensedLight", size: fontSize)
        case .light:
            font = UIFont(name: "AmericanTypewriter-Light", size: fontSize)
        case .regular:
            font = UIFont(name: "AmericanTypewriter", size: fontSize)
        case .medium:
            font = UIFont(name: "AmericanTypewriter", size: fontSize)
        case .semibold:
            font = UIFont(name: "AmericanTypewriter-Bold", size: fontSize)
        case .bold:
            font = UIFont(name: "AmericanTypewriter-Bold", size: fontSize)
        case .heavy:
            font = UIFont(name: "AmericanTypewriter-CondensedBold", size: fontSize)
        case .black:
            font = UIFont(name: "AmericanTypewriter-CondensedBold", size: fontSize)
        default:
            font = UIFont(name: "AmericanTypewriter", size: fontSize)
        }

        if font == nil {
            log.error("NIL font returned")
            return UIFont.systemFont(ofSize: fontSize, weight: weight)
        } else {
            return font!
        }
    }

}


