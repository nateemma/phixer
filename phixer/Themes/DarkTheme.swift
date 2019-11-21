
//
//  DarkTheme.swift
//
//
// Copyright (c) 2019 Phil Price
//

import UIKit
import Foundation


// Dark Theme
class DarkTheme: CustomTheme {

    
    // init values for this theme
    override init(){
        
        super.init()
        
        description = "Dark Theme"
        
        barStyle = .black
        
        navbarColor = UIColor.black
        navbarTintColor = UIColor.white
        navbarTextColor = UIColor.white
        mainColor = UIColor.black
        textColor = UIColor.white
        backgroundColor = UIColor.black
        secondaryColor = UIColor.flatBlack()
        titleColor = UIColor.flatBlackDark()
        titleTextColor = UIColor.white
        subtitleTextColor = UIColor.flatWhite()
        subtitleColor = UIColor.flatBlack()
        buttonColor = UIColor.flatGray()
        borderColor = UIColor.flatGray()
        highlightColor = UIColor.flatYellowDark()
        tintColor = UIColor.flatWhite()
    }
    
    
    // override the default (system) font
    override func  getFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        // default is to return the system font
        // use font AppleSDGothicNeo
        var font: UIFont?
        
        // there is no generic API for retrieving a (non-system) font using both size and weight, so we have to explicitly code for it
        // Note that not all font families support all weights, so you have to look at the documentation
        // See http://iosfonts.com/ for fonts available by default with iOS
        switch weight {
        case .ultraLight:
            font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: fontSize)
        case .thin:
            font = UIFont(name: "AppleSDGothicNeo-Thin", size: fontSize)
        case .light:
            font = UIFont(name: "AppleSDGothicNeo-Light", size: fontSize)
        case .regular:
            font = UIFont(name: "AppleSDGothicNeo-Regular", size: fontSize)
        case .medium:
            font = UIFont(name: "AppleSDGothicNeo-Medium", size: fontSize)
        case .semibold:
            font = UIFont(name: "AppleSDGothicNeo-SemiBold", size: fontSize)
        case .bold:
            font = UIFont(name: "AppleSDGothicNeo-Bold", size: fontSize)
        case .heavy:
            font = UIFont(name: "AppleSDGothicNeo-Bold", size: fontSize)
        case .black:
            font = UIFont(name: "AppleSDGothicNeo-Bold", size: fontSize)
        default:
            font = UIFont(name: "AppleSDGothicNeo-Regular", size: fontSize)
        }
        
        return font ?? UIFont.systemFont(ofSize: fontSize, weight: weight)
    }
}


