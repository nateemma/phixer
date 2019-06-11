//
//  ColorPickerController.swift
//  Controller to display a colour picker wheel and allow the user to pick or enter a colour
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import Neon

import GoogleMobileAds


// delegate method to let the launching ViewController know that this one has finished
protocol ColorPickerControllerDelegate: class {
    // returns the chosen Colour. Nil is returned if the user cancelled
    func colorPicked(_ color:UIColor?)
}



// This is the View Controller for developing a color scheme

class ColorPickerController: CoordinatedController {
    
   weak var delegate: ColorPickerControllerDelegate? = nil
    
    // Main Views
    var adView: GADBannerView! = GADBannerView()
    //var colorWheelView:ISColorWheel! = ISColorWheel()
    var colorWheelView:ColorWheelView? = nil
    var rgbView:RGBSliderView! = RGBSliderView()
    var hsbView:HSBSliderView! = HSBSliderView()
    var controlView:UIView! = UIView()
    

    
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    var selectedColor:UIColor = UIColor.flatGreen

    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////

    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Color Picker"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "default"
    }
   
    
    /////////////////////////////
    // MARK: - Boilerplate
    /////////////////////////////

    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    public func setColor(_ color:UIColor){
        selectedColor = color
        updateColors()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: type(of: self))) ==========")

        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        

        doInit()
        doLayout()
        
        // start Ads
        if (UISettings.showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        self.updateColors()

    }
    
    
    
    
    /////////////////////////////
    // MARK: - Initialisation
    /////////////////////////////

    var initDone:Bool = false

    
    func doInit(){
        
        if (!initDone){
            initDone = true
            
            selectedColor = UIColor.flatGreen
        }
    }
    
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
 
        UISettings.showAds = false // debug
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
       
         
        // Ads
        if (UISettings.showAds){
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
        }

        if (UISettings.showAds){
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads")
            adView.isHidden = true
        }
        
        // ColorWheel
        layoutColorWheel()
        layoutRGB()
        layoutHSB()
        layoutControls()
        view.addSubview(colorWheelView!)
        view.addSubview(rgbView)
        view.addSubview(hsbView)
        view.addSubview(controlView)

        
        // layout constraints
        if (UISettings.showAds){
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
            colorWheelView?.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: (colorWheelView?.frame.size.height)!)
        } else {
            colorWheelView?.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: (colorWheelView?.frame.size.height)!)
        }
        controlView.anchorAndFillEdge(.bottom, xPad: 0, yPad: UISettings.topBarHeight, otherSize: controlView.frame.size.height)
        hsbView.align(.aboveCentered, relativeTo: controlView, padding: 0, width: displayWidth, height: hsbView.frame.size.height)
        rgbView.align(.aboveCentered, relativeTo: hsbView, padding: 0, width: displayWidth, height: rgbView.frame.size.height)

        updateColors()
    }
    
   
    
    /////////////////////////////
    // MARK: - Layout Functions
    /////////////////////////////
 
    //NOTE: make sure height percentages add up to 1.0 (or less)

    func layoutColorWheel(){
        
        let w = min(displayHeight*0.4,displayWidth*0.8)
        colorWheelView = ColorWheelView(frame:CGRect(x: 0, y: 0, width: w, height: w))
        colorWheelView?.frame.size.height = w
        colorWheelView?.frame.size.width = w
        colorWheelView?.backgroundColor = theme.backgroundColor
        //colorWheelView?.continuous = false
        colorWheelView?.delegate = self
        
    }
    
    func layoutRGB(){
        rgbView.frame.size.height = displayHeight * 0.2
        rgbView.frame.size.width = displayWidth
        rgbView.backgroundColor = theme.backgroundColor
        rgbView.layer.borderWidth = 0.5
        rgbView.layer.borderColor = theme.borderColor.cgColor
        rgbView.delegate = self
    }
    
    func layoutHSB(){
        hsbView.frame.size.height = displayHeight * 0.2
        hsbView.frame.size.width = displayWidth
        hsbView.backgroundColor = theme.backgroundColor
        hsbView.layer.borderWidth = 0.5
        hsbView.layer.borderColor = theme.borderColor.cgColor
        hsbView.delegate = self
    }
    
    
    func layoutControls(){
        controlView.frame.size.width = displayWidth
        controlView.frame.size.height = displayHeight * 0.1
    
        // build a view with a "Accept" Button and a "Cancel" button
        let cancelButton:BorderedButton = BorderedButton()
        cancelButton.frame.size.width = (displayWidth / 2.0) - 32
        cancelButton.frame.size.height = controlView.frame.size.height - 16
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.useGradient = true
        cancelButton.backgroundColor = theme.highlightColor
        controlView.addSubview(cancelButton)
        
        let acceptButton:BorderedButton = BorderedButton()
        acceptButton.frame.size = cancelButton.frame.size
        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.useGradient = true
        acceptButton.backgroundColor = theme.highlightColor
        controlView.addSubview(acceptButton)
        
        // distribute across the control view
        controlView.groupInCenter(group: .horizontal, views: [acceptButton, cancelButton], padding: 16, width: acceptButton.frame.size.width, height: acceptButton.frame.size.height)

        // add touch handlers
        acceptButton.addTarget(self, action: #selector(self.doneDidPress), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)

    }
    
    private func updateColors(){
        //colorWheelView?.setValue(selectedColor, forKey: "currentColor")
        //colorWheelView?.setCurrentColor(selectedColor)
        colorWheelView?.setColor(selectedColor)
        rgbView.setColor(selectedColor)
        hsbView.setColor(selectedColor)
    }

    
    fileprivate func updateColorWheel() {

        self.colorWheelView?.setColor(self.selectedColor)

/* Obj-C version:
        // color wheel view seems a little funky when dealing with brightness, so set explicitly

        var h:CGFloat=0, s:CGFloat=0, b:CGFloat=0, a:CGFloat=0
        selectedColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        //self.colorWheelView?.setValue(self.selectedColor, forKey: "currentColor")
        //self.colorWheelView?.currentColor = selectedColor
        //self.colorWheelView?.brightness = b
 */
    }

    /////////////////////////////
    // MARK: - Touch/Callback  Handler(s)
    /////////////////////////////
    
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        // NOTE: in this case, back is the same as cancel
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion:  { self.delegate?.colorPicked(nil) })
            return
        }
    }

    @objc func cancelDidPress(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion:  { self.delegate?.colorPicked(nil) })
            return
        }
    }
    
    @objc func doneDidPress(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion:  { self.delegate?.colorPicked(self.selectedColor) })
            return
        }
    }

    
} // ColorPickerController


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////

extension ColorPickerController: RGBSliderViewDelegate {
    func rgbColorChanged(_ color: UIColor) {
        if !color.matches(self.selectedColor) {
            log.verbose("RGB Colour changed: \(color) (\(color.hexValue()))")
            self.selectedColor = color
            DispatchQueue.main.async(execute: {
                self.updateColorWheel()
                self.hsbView.setColor(self.selectedColor)
            })
        }
    }
}

extension ColorPickerController: HSBSliderViewDelegate {
    func hsbColorChanged(_ color: UIColor) {
        if !color.matches(self.selectedColor) {
            log.verbose("HSB Colour changed: \(color) (\(color.hexValue()))")
            self.selectedColor = color
            DispatchQueue.main.async(execute: {
                self.updateColorWheel()
                self.rgbView.setColor(self.selectedColor)

            })
        }
    }
}

/***
extension ColorPickerController: ISColorWheelDelegate {
    func colorWheelDidChangeColor(_ colorWheel: ISColorWheel!) {
        if let color = colorWheel.currentColor {
            if !colorMatches(self.selectedColor, color) {
                log.verbose("Colour wheel changed: \(color)")
                self.selectedColor = color
                DispatchQueue.main.async(execute: {
                    self.rgbView.setColor(self.selectedColor)
                    self.hsbView.setColor(self.selectedColor)
                })
            }
        }
    }
 ***/

extension ColorPickerController: ColorWheelDelegate {
    func colorSelected(_ color: UIColor) {
        if !color.matches(self.selectedColor) {
            log.verbose("Colour wheel changed: \(color) (\(color.hexValue()))")
            self.selectedColor = color
            DispatchQueue.main.async(execute: {
                self.rgbView.setColor(self.selectedColor)
                self.hsbView.setColor(self.selectedColor)
            })
        }
    }
}
