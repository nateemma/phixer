
//
//  ThemeManager.swift
//  phixer
//
// Copyright (c) 2019 Nateemma LLC
//

import UIKit
import Foundation


// class that holds the theme options (styles, coours, font) that are set in the various themes


// (Static) class for accessing the themes
class ThemeManager {
    
    // static vars that hold the theme data
    private static var themeDictionary:[String:CustomTheme] = [:]
    private static var currTheme:CustomTheme? = nil
    private static let currThemeKey = "phixerTheme"
    private static var currKey:String = ""
    private static let defaultKey:String = "default"
    
    // default theme. Done this way so that an instance is guaranteed, and the compiler will flag any missing fields if changes are made
    private static var defaultTheme:CustomTheme = CustomTheme()
  
    private static var initDone:Bool = false
    
    
    
    private static func checkSetup(){
        if !initDone {
            initDone = true
            
            // populate the theme dictionary
            // TODO: if we allow user-defined themes then we'll need to save and restore
            log.debug("Loading Themes...")
            ThemeManager.themeDictionary = [:]
            
            // Load the available themes
            // I really should put this in a factory
            ThemeManager.themeDictionary[ThemeManager.defaultKey] = ThemeManager.defaultTheme
            ThemeManager.themeDictionary["dark"] = DarkTheme()
            ThemeManager.themeDictionary["light"] = LightTheme()
            ThemeManager.themeDictionary["red"] = RedTheme()
            ThemeManager.themeDictionary["blue"] = BlueTheme()
            ThemeManager.themeDictionary["warhol"] = WarholTheme()

            currKey = getSavedTheme()
        }
    }

    
    
    // get the stored value for the theme
    static func getSavedTheme() -> String{
        checkSetup()
        var key:String = ""
        // if let storedTheme = (UserDefaults.standard.value(forKey: ThemeManager.currThemeKey) as AnyObject).stringValue {
        if let storedTheme = UserDefaults.standard.string(forKey: ThemeManager.currThemeKey)  {
            key = storedTheme
            log.debug("Retrieved theme: \(key)")
        } else {
            key = ThemeManager.defaultKey
            log.debug("No theme saved, setting to: \(key)")
       }
        return key
    }
    
    
    // save the theme to persistent storage
    static func saveTheme(key:String){
        UserDefaults.standard.set(key, forKey: ThemeManager.currThemeKey)
        // Swift 2:
        //UserDefaults.standard.setValue(key, forKey: ThemeManager.currThemeKey)
        //UserDefaults.standard.synchronize()
            log.debug("Saved theme: \(key)")
    }
    
    
    // get the current theme key
    static func getCurrentThemeKey() -> String {
        if currKey.isEmpty {
            currKey = getSavedTheme()
        }
        return currKey
    }
   
    
    // get the current Theme
    static func currentTheme() -> CustomTheme {
        checkSetup()

        // check user defaults. This allows settings to be used across apps or pods/libraries
        if currKey.isEmpty {
            currKey = getSavedTheme()
        }
        if (themeDictionary[currKey] != nil) {
            currTheme =  themeDictionary[currKey]
        } else {
            currKey = defaultKey
            currTheme =  defaultTheme
        }
        
        return currTheme!
    }
    
    
    
    // get the list of available themes
    public static func getThemeList() -> [String]{
        checkSetup()
        return Array(themeDictionary.keys).sorted()
    }
    
    
    
    // get parameters for a theme (without changing the current theme). Returns nil if not found
    public static func getTheme(_ key:String) -> CustomTheme? {
        checkSetup()
        return themeDictionary[key]
    }
    
    
    
    // apply the specified theme
    static func applyTheme(key: String) {
        checkSetup()

        
        if themeDictionary[key] != nil {
            currKey = key
            currTheme = themeDictionary[key]
            log.debug("Applying theme: \(key) (\(currTheme?.description))")
            
            // First persist the selected theme using NSUserDefaults.
            saveTheme(key: currKey)
            
            // Get the current (selected) theme and apply the main color to the tintColor property of the application’s window.
            let sharedApplication = UIApplication.shared
            sharedApplication.delegate?.window??.tintColor = currTheme?.mainColor
            
            //Note: do not set UIView.appearance(), as this can cause problems with built-in components (Alerts, PhotoPicker etc.)
            
            UILabel.appearance().backgroundColor = currTheme?.backgroundColor
            UILabel.appearance().textColor = currTheme?.textColor

            // messes up builtin collections after iOS13
            //UICollectionView.appearance().backgroundColor = currTheme?.backgroundColor
            
            UISwitch.appearance().backgroundColor = currTheme?.backgroundColor
            UISwitch.appearance().onTintColor = currTheme?.highlightColor.withAlphaComponent(0.6)
            UISwitch.appearance().thumbTintColor = currTheme?.titleTextColor
            UISwitch.appearance().tintColor = currTheme?.borderColor
            
            UISlider.appearance().backgroundColor = currTheme?.backgroundColor
            UISlider.appearance().tintColor = currTheme?.highlightColor

            UINavigationBar.appearance().backgroundColor = currTheme?.backgroundColor
            UINavigationBar.appearance().tintColor = currTheme?.tintColor
            UINavigationBar.appearance().barTintColor = currTheme?.backgroundColor
            UINavigationBar.appearance().isTranslucent = false

            UITabBar.appearance().backgroundColor = currTheme?.backgroundColor

        } else {
            log.error ("Unknown Theme: \(key). Available themes: \(getThemeList())")
        }
    }
}
