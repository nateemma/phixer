
//
//  LightTheme.swift
//
//
// Copyright (c) 2019 Phil Price
//

import UIKit
import Foundation



// Light Theme
class LightTheme: CustomTheme {

    
    // init values for this theme
    override init(){
        
        super.init()
        
        description = "Light Theme"
        
        barStyle = .default
        
        navbarColor = UIColor.white
        navbarTintColor = UIColor.black
        navbarTextColor = UIColor.black
        mainColor = UIColor.white
        textColor = UIColor.black
        backgroundColor = UIColor.white
        secondaryColor = UIColor.flatGray()
        titleColor = UIColor.white
        titleTextColor = UIColor.black
        subtitleColor = UIColor.flatWhite()
        subtitleTextColor = UIColor.black
        buttonColor = UIColor.flatSkyBlueDark()
        borderColor = UIColor.flatGray()
        highlightColor = UIColor.flatSkyBlue()
        tintColor = UIColor.black
    }
}

