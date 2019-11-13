
//
//  ThemeManager.swift
//  ProjectThemeTest
//
// Copyright (c) 2017 Abhilash
//

import UIKit
import Foundation


// struct that holds the colour/icon options that are set in the various themes
struct ThemeParameters {
    private var _key: String = ""
    private var _description: String = ""
    private var _mainColor: UIColor = UIColor.black
    private var _textColor: UIColor = UIColor.white
    private var _barStyle: UIBarStyle = .default
    private var _backgroundColor: UIColor = UIColor.black
    private var _secondaryColor: UIColor = UIColor.darkGray
    private var _titleColor: UIColor = UIColor.black
    private var _titleTextColor: UIColor = UIColor.white
    private var _subtitleTextColor: UIColor = UIColor.white
    private var _subtitleColor: UIColor = UIColor.systemGreen
    private var _buttonColor: UIColor = UIColor.systemGreen
    private var _borderColor: UIColor = UIColor.darkGray
    private var _highlightColor: UIColor = UIColor.systemGreen
    private var _tintColor: UIColor = UIColor.white
    
    var key:String
    var description:String
    var mainColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.systemBackground
            } else {
                return _mainColor
            }
        }
        set {
            _mainColor = newValue
        }
    }
    
    var textColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.label
            } else {
                return _textColor
            }
        }
        set {
            _backgroundColor = newValue
        }
    }
    
    var barStyle: UIBarStyle = .default
    
    var backgroundColor: UIColor  {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.systemBackground
            } else {
                return _backgroundColor
            }
        }
        set {
            _backgroundColor = newValue
        }
    }
    
    var secondaryColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.secondarySystemBackground
            } else {
                return _secondaryColor
            }
        }
        set {
            _secondaryColor = newValue
        }
    }
    
    var titleColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.secondarySystemBackground
            } else {
                return _titleColor
            }
        }
        set {
            _titleColor = newValue
        }
    }
    
    var titleTextColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.label
            } else {
                return _titleTextColor
            }
        }
        set {
            _titleTextColor = newValue
        }
    }
    
    var subtitleTextColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.label
            } else {
                return _subtitleTextColor
            }
        }
        set {
            _subtitleTextColor = newValue
        }
    }
    
    var subtitleColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.tertiarySystemBackground
            } else {
                return _subtitleColor
            }
        }
        set {
            _subtitleColor = newValue
        }
    }
    
    var buttonColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.tertiarySystemFill
            } else {
                return _buttonColor
            }
        }
        set {
            _buttonColor = newValue
        }
    }
    
    var borderColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.systemTeal
            } else {
                return _borderColor
            }
        }
        set {
            _borderColor = newValue
        }
    }
    
    var highlightColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.systemBlue
            } else {
                return _highlightColor
            }
        }
        set {
            _highlightColor = newValue
        }
    }
    
    var tintColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                return UIColor.label
            } else {
                return _tintColor
            }
        }
        set {
            _tintColor = newValue
        }
    }

    // since we includers some get/set accessors, we need to explicitly add the default initialiser
    init(key: String, description: String, mainColor: UIColor, textColor: UIColor, barStyle: UIBarStyle, backgroundColor: UIColor,
         secondaryColor: UIColor, titleColor: UIColor, titleTextColor: UIColor, subtitleTextColor: UIColor, subtitleColor: UIColor,
         buttonColor: UIColor, borderColor: UIColor, highlightColor: UIColor, tintColor: UIColor) {
        
        self.key = key
        self.description = description
        self.mainColor = mainColor
        self.textColor = textColor
        self.barStyle = barStyle
        self.backgroundColor = backgroundColor
        self.secondaryColor = secondaryColor
        self.titleColor = titleColor
        self.titleTextColor = titleTextColor
        self.subtitleTextColor = subtitleTextColor
        self.subtitleColor = subtitleColor
        self.buttonColor = buttonColor
        self.borderColor = borderColor
        self.highlightColor = highlightColor
        self.tintColor = tintColor
    }
    
    // and since we added a custom init, we have to define a default init
    init(){
        self.key = _key
        self.description = _description
        self.mainColor = _mainColor
        self.textColor = _textColor
        self.barStyle = .default
        self.backgroundColor = _backgroundColor
        self.secondaryColor = _secondaryColor
        self.titleColor = _titleColor
        self.titleTextColor = _titleTextColor
        self.subtitleTextColor = _subtitleTextColor
        self.subtitleColor = _subtitleColor
        self.buttonColor = _buttonColor
        self.borderColor = _borderColor
        self.highlightColor = _highlightColor
        self.tintColor = _tintColor
    }
}




// (Static) class for accessing the themes
class ThemeManager {
    
    // static vars that hold the theme data
    private static var themeDictionary:[String:ThemeParameters] = [:]
    private static var currTheme:ThemeParameters? = nil
    private static let currThemeKey = "phixerTheme"
    private static var currKey:String = ""
    private static let defaultKey:String = "default"
    
    // default theme. Done this way so that an instance is guaranteed, and the compiler will flag any missing fields if changes are made
    private static var defaultTheme:ThemeParameters = ThemeParameters(key: defaultKey,
                                                                      description: "Default Theme",
                                                                      mainColor: UIColor.black,
                                                                      textColor: UIColor.white,
                                                                      barStyle: .default,
                                                                      backgroundColor: UIColor.black,
                                                                      secondaryColor: UIColor.flatGrayDark(),
                                                                      titleColor: UIColor.black,
                                                                      titleTextColor: UIColor.white,
                                                                      subtitleTextColor: UIColor.white,
                                                                      subtitleColor: UIColor.flatMintDark(),
                                                                      buttonColor: UIColor.flatMint(),
                                                                      borderColor: UIColor.flatGrayDark(),
                                                                      highlightColor: UIColor.flatMint(),
                                                                      tintColor: UIColor.flatWhite())
  
    private static var initDone:Bool = false
    
    
    
    private static func checkSetup(){
        if !initDone {
            initDone = true
            
            // populate the theme dictionary
            // TODO: if we allow user-defined themes then we'll need to save and restore
            log.debug("Loading Themes...")
            ThemeManager.themeDictionary = [:]
            ThemeManager.themeDictionary[ThemeManager.defaultKey] = ThemeManager.defaultTheme
            
            ThemeManager.themeDictionary["dark"] = ThemeParameters(key: "dark",
                                                                   description: "Dark Theme",
                                                                   mainColor: UIColor.black,
                                                                   textColor: UIColor.white,
                                                                   barStyle: .default,
                                                                   backgroundColor: UIColor.black,
                                                                   secondaryColor: UIColor.flatBlack(),
                                                                   titleColor: UIColor.flatBlackDark(),
                                                                   titleTextColor: UIColor.white,
                                                                   subtitleTextColor: UIColor.flatWhite(),
                                                                   subtitleColor: UIColor.flatBlack(),
                                                                   buttonColor: UIColor.flatGray(),
                                                                   borderColor: UIColor.flatGray(),
                                                                   highlightColor: UIColor.flatYellowDark(),
                                                                   tintColor: UIColor.flatWhite())
            
            ThemeManager.themeDictionary["light"] = ThemeParameters(key: "light",
                                                                    description: "Light Theme",
                                                                    mainColor: UIColor.white,
                                                                    textColor: UIColor.black,
                                                                    barStyle: .black,
                                                                    backgroundColor: UIColor.white,
                                                                    secondaryColor: UIColor.flatGray(),
                                                                    titleColor: UIColor.black,
                                                                    titleTextColor: UIColor.white,
                                                                    subtitleTextColor: UIColor.white,
                                                                    subtitleColor: UIColor.flatSkyBlueDark(),
                                                                    buttonColor: UIColor.flatSkyBlueDark(),
                                                                    borderColor: UIColor.flatGray(),
                                                                    highlightColor: UIColor.flatSkyBlue(),
                                                                    tintColor: UIColor.flatBlack())
            
            ThemeManager.themeDictionary["red"] = ThemeParameters(key: "red",
                                                                  description: "Red Theme",
                                                                  mainColor: UIColor.white,
                                                                  textColor: UIColor.flatRedDark(),
                                                                  barStyle: .black,
                                                                  backgroundColor: UIColor.white,
                                                                  secondaryColor: UIColor.flatRedDark(),
                                                                  titleColor: UIColor.flatRed(),
                                                                  titleTextColor: UIColor.white,
                                                                  subtitleTextColor: UIColor.white,
                                                                  subtitleColor: UIColor.flatRed(),
                                                                  buttonColor: UIColor.flatRedDark(),
                                                                  borderColor: UIColor.flatPink(),
                                                                  highlightColor: UIColor.flatPink(),
                                                                  tintColor: UIColor.flatRed())
            
            ThemeManager.themeDictionary["blue"] = ThemeParameters(key: "blue",
                                                                  description: "Blue Theme",
                                                                  mainColor: UIColor.white,
                                                                  textColor: UIColor.flatBlueDark(),
                                                                  barStyle: .black,
                                                                  backgroundColor: UIColor.white,
                                                                  secondaryColor: UIColor.flatSkyBlueDark(),
                                                                  titleColor: UIColor.flatSkyBlue(),
                                                                  titleTextColor: UIColor.white,
                                                                  subtitleTextColor: UIColor.white,
                                                                  subtitleColor: UIColor.flatSkyBlue(),
                                                                  buttonColor: UIColor.flatSkyBlueDark(),
                                                                  borderColor: UIColor.flatBlueDark(),
                                                                  highlightColor: UIColor.flatOrange(),
                                                                  tintColor: UIColor.flatSkyBlueDark())

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
    static func currentTheme() -> ThemeParameters {
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
    public static func getTheme(_ key:String) -> ThemeParameters? {
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
            UINavigationBar.appearance().tintColor = currTheme?.highlightColor

        } else {
            log.error ("Unknown Theme: \(key). Available themes: \(getThemeList())")
        }
    }
}
