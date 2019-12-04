
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

    // from online colour palette
    let warholRed = UIColor(hex: "F23A3A")
    let warholGreen = UIColor(hex: "77CC62")
    let warholBlue = UIColor(hex: "5280C7")
    let warholYellow = UIColor(hex: "F0D848")
    let warholPink = UIColor(hex: "FA8C82")

    // Warhol colours, sampled from Warhol's Marilyn Monroe paintings
    let lightPink = UIColor(hex: "ebcfc4")
    let darkPink = UIColor(hex: "D95D77")
    let lightRed = UIColor(hex: "e76581")
    let darkRed = UIColor(hex: "c95351")
    let lightBlue = UIColor(hex: "82b8d0")
    let darkBlue = UIColor(hex: "0f75bf")
    let lightGreen = UIColor(hex: "7e9d64")
    let darkGreen = UIColor(hex: "4c6d5c")
    let lightYellow = UIColor(hex: "feda60")
    let darkYellow = UIColor(hex: "f3c453")
    let lightOrange = UIColor(hex: "f2c34d")
    let darkOrange = UIColor(hex: "e99b67")
    let lightTeal = UIColor(hex: "90becb")
    let darkTeal = UIColor(hex: "88b7bd")

    
    /*
    let lightPink = UIColor(red: 214, green: 90, blue: 116, alpha: 1)

    
    let lightRed = UIColor(red: 221, green: 117, blue: 152, alpha: 1)
    let darkRed = UIColor(red: 198, green: 80, blue: 78, alpha: 1)
    
    let lightBlue = UIColor(red: 123, green: 181, blue: 201, alpha: 1)
    let darkBlue = UIColor(red: 9, green: 112, blue: 181, alpha: 1)
    
    let lightGreen = UIColor(red: 125, green: 154, blue: 96, alpha: 1)
    let darkGreen = UIColor(red: 79, green: 129, blue: 128, alpha: 1)
    
    let lightYellow = UIColor(red: 255, green: 219, blue: 99, alpha: 1)
    let darkYellow = UIColor(red: 242, green: 195, blue: 81, alpha: 1)
    
    let lightOrange = UIColor(red: 246, green: 189, blue: 82, alpha: 1)
    let darkOrange = UIColor(red: 232, green: 161, blue: 107, alpha: 1)

    let lightTeal = UIColor(red: 154, green: 194, blue: 202, alpha: 1)
    let darkTeal = UIColor(red: 135, green: 180, blue: 186, alpha: 1)
*/

    // init values for this theme
    override init(){
        
        super.init()
        
        description = "Andy Warhol"
        
        barStyle = .default
        
        /* using warhol colour palette
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
 */
        
        // using Marilyn colours
        navbarColor = lightGreen
        navbarTintColor = darkBlue
        navbarTextColor = UIColor.black
        mainColor = darkPink
        textColor = UIColor.black
        backgroundColor = darkPink
        secondaryColor = lightOrange
        titleColor = lightBlue
        titleTextColor = darkGreen
        subtitleTextColor = UIColor.black
        subtitleColor = lightGreen
        buttonColor = lightTeal
        borderColor = darkOrange
        highlightColor = lightTeal
        tintColor = lightYellow

    }
    
    
    // override the default (system) font
    override func  getFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {

        var font: UIFont?
        
        // there is no generic API for retrieving a (non-system) font using both size and weight, so we have to explicitly code for it
        // Note that not all font families support all weights, so you have to look at the documentation
        // See http://iosfonts.com/ for fonts available by default with iOS
        
        /* AmericanTypewriter looks accurate, but smaller sizes are hard to read
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
         */

        // Superclarendon is not as good as AmericanTypewriter, but has more font sizes
        switch weight {
        case .ultraLight:
            font = UIFont(name: "Superclarendon-LightItalic", size: fontSize)
        case .thin:
            font = UIFont(name: "Superclarendon-LightItalic", size: fontSize)
        case .light:
            font = UIFont(name: "Superclarendon-Light", size: fontSize)
        case .regular:
            font = UIFont(name: "Superclarendon-Regular", size: fontSize)
        case .medium:
            font = UIFont(name: "Superclarendon-Regular", size: fontSize)
        case .semibold:
            font = UIFont(name: "Superclarendon-BoldItalic", size: fontSize)
        case .bold:
            font = UIFont(name: "Superclarendon-Bold", size: fontSize)
        case .heavy:
            font = UIFont(name: "Superclarendon-BlackItalic", size: fontSize)
        case .black:
            font = UIFont(name: "Superclarendon-Black", size: fontSize)
        default:
            font = UIFont(name: "Superclarendon-Light", size: fontSize)
        }

        
        if font == nil {
            log.error("NIL font returned")
            return UIFont.systemFont(ofSize: fontSize, weight: weight)
        } else {
            return font!
        }
    }

}


