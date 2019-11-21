
//
//  CustomTheme.swift
//
//
// Copyright (c) 2019 Phil Price
//

import UIKit
import Foundation


// default implementation of class that holds the theme options (styles, colours, font) that are set in the various themes
// Actual themes should subclass from this theme
class CustomTheme {
    var description: String
    var barStyle: UIBarStyle
    var mainColor: UIColor
    var navbarColor: UIColor
    var navbarTextColor: UIColor
    var navbarTintColor: UIColor
    var textColor: UIColor
    var backgroundColor: UIColor
    var secondaryColor: UIColor
    var titleColor: UIColor
    var titleTextColor: UIColor
    var subtitleTextColor: UIColor
    var subtitleColor: UIColor
    var buttonColor: UIColor
    var borderColor: UIColor
    var highlightColor: UIColor
    var tintColor: UIColor
    
    // deafult values
    init(){
        description = "Default Theme"
        barStyle = .default
        
        // if >= iOS13.x, use light/dark mode system colours. Otherwise set manually
        if #available(iOS 13.0, *) {
            description = "Default Light/Dark Mode"
            navbarColor = UIColor.systemBackground
            navbarTintColor = UIColor.label
            navbarTextColor = UIColor.label
            mainColor = UIColor.systemBackground
            textColor = UIColor.label
            backgroundColor = UIColor.systemBackground
            secondaryColor = UIColor.secondarySystemBackground
            titleColor = UIColor.secondarySystemBackground
            titleTextColor = UIColor.label
            subtitleTextColor = UIColor.label
            subtitleColor = UIColor.tertiarySystemBackground
            buttonColor = UIColor.tertiarySystemFill
            borderColor = UIColor.systemTeal
            highlightColor = UIColor.systemBlue
            tintColor = UIColor.label
        } else {
            navbarColor = UIColor.black
            navbarTintColor = UIColor.white
            navbarTextColor = UIColor.white
            mainColor = UIColor.black
            textColor = UIColor.white
            backgroundColor = UIColor.black
            secondaryColor = UIColor.darkGray
            titleColor = UIColor.black
            titleTextColor = UIColor.white
            subtitleTextColor = UIColor.white
            subtitleColor = UIColor.systemGreen
            buttonColor = UIColor.systemGreen
            borderColor = UIColor.darkGray
            highlightColor = UIColor.systemGreen
            tintColor = UIColor.white
        }
    }
    
    // get the font for the theme
    public func  getFont(ofSize fontSize: CGFloat, weight: UIFont.Weight) -> UIFont {
        // default is to return the system font
        return UIFont.systemFont(ofSize: fontSize, weight: weight)
    }
}


