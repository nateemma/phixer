
//
//  RedTheme.swift
//
//
// Copyright (c) 2019 Phil Price
//

import UIKit
import Foundation

// Red Theme
class RedTheme: CustomTheme {

    
    // init values for this theme
    override init(){
        
        super.init()
        
        description = "Red Theme"
        
        barStyle = .default
        
        navbarColor = UIColor.flatRed()
        navbarTintColor = UIColor.white
        navbarTextColor = UIColor.white
        mainColor = UIColor.white
        textColor = UIColor.flatRedDark()
        backgroundColor = UIColor.white
        secondaryColor = UIColor.flatRedDark()
        titleColor = UIColor.flatRed()
        titleTextColor = UIColor.white
        subtitleTextColor = UIColor.white
        subtitleColor = UIColor.flatRed()
        buttonColor = UIColor.flatRedDark()
        borderColor = UIColor.flatRed()
        highlightColor = UIColor.flatRed()
        tintColor = UIColor.flatRed()
    }
}


