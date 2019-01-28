//
//  HSBSliderView.swift
//  A compound View that displays a set of RGB Sliders and equivalent text entry fields
//  A delegate method provides the value back to the calling controller
//
//  Created by Philip Price on 10/27/18
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon



// Interface required of controlling View
protocol HSBSliderViewDelegate: class {
    func hsbColorChanged(_ color:UIColor)
}


class HSBSliderView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    
    var initDone: Bool = false
    
    let sliderHeight: CGFloat = 32.0
    
    // RGB display items
    let hSlider:GradientSlider = GradientSlider()
    let sSlider:GradientSlider = GradientSlider()
    let bSlider:GradientSlider = GradientSlider()
    let hLabel:UILabel = UILabel()
    let sLabel:UILabel = UILabel()
    let bLabel:UILabel = UILabel()
    let hEntry:UITextField = UITextField()
    let sEntry:UITextField = UITextField()
    let bEntry:UITextField = UITextField()

    // Colour values
    var hValue:CGFloat = 0.0
    var sValue:CGFloat = 0.0
    var bValue:CGFloat = 0.0
    var aValue:CGFloat = 1.0
    var currColor:UIColor = .black
    var oldColor:UIColor = .black

    // delegate for notification
    weak var delegate: HSBSliderViewDelegate?

    
    public func setColor(_ color:UIColor){
        currColor = color
        color.getHue(&hValue, saturation: &sValue, brightness: &bValue, alpha: &aValue)
        hSlider.setValue(hValue, animated: false)
        sSlider.setValue(sValue, animated: false)
        bSlider.setValue(bValue, animated: false)
        
        updateFromSliders()
        oldColor = currColor // save for later comparison

    }
    

    
    
    convenience init(){
        self.init(frame: CGRect.zero)
        
        initDone = false
        
        // don't do anything until the coor has been set
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        initViews()
       // don't do anything else until colour is set
    }

    
    fileprivate func clearSubviews(){
        for v in self.subviews{
            v.removeFromSuperview()
        }
    }
    
    // get values from sliders and update associated text
    func updateFromSliders(){
        hValue = truncate(CGFloat(hSlider.value), to:1000)
        sValue = truncate(CGFloat(sSlider.value), to:1000)
        bValue = truncate(CGFloat(bSlider.value), to:1000)
        log.debug("h:\(hValue) s:\(sValue) b:\(bValue)")
        currColor = UIColor(hue: hValue, saturation: sValue, brightness: bValue, alpha: 1.0)
        hEntry.text = String(format:"%3d",Int(hValue*100))
        sEntry.text = String(format:"%3d",Int(sValue*100))
        bEntry.text = String(format:"%3d",Int(bValue*100))
        hSlider.setGradientForHueWithSaturation(sValue, brightness: bValue)
        sSlider.setGradientForSaturationWithHue(hValue, brightness: bValue)
        bSlider.setGradientForBrightnessWithHue(hValue, saturation: sValue)
    }
    
    // get values from text and update associated values
    func updateFromText(){
        hValue = truncate(CGFloat(Int(hEntry.text!)!) / 100.0, to:1000)
        sValue = truncate(CGFloat(Int(sEntry.text!)!) / 100.0, to:1000)
        bValue = truncate(CGFloat(Int(bEntry.text!)!) / 100.0, to:1000)
        log.debug("h:\(hValue) s:\(sValue) b:\(bValue)")
        currColor = UIColor(hue: hValue, saturation: sValue, brightness: bValue, alpha: 1.0)
        hSlider.value = hValue
        sSlider.value = sValue
        bSlider.value = bValue
        hSlider.setGradientForHueWithSaturation(sValue, brightness: bValue)
        sSlider.setGradientForSaturationWithHue(hValue, brightness: bValue)
        bSlider.setGradientForBrightnessWithHue(hValue, saturation: sValue)
        hSlider.setNeedsDisplay()
        sSlider.setNeedsDisplay()
        bSlider.setNeedsDisplay()
    }

    fileprivate func truncate(_ val:CGFloat, to:Int) -> CGFloat{
        return round (val * CGFloat(to)) / CGFloat(to)
    }
    
    fileprivate func initViews(){
        
        //if (!initDone && (currFilterDesc != nil)){
        if (!initDone){
           // initDone = true
            self.backgroundColor = UIColor.clear

            let sliderWidth:CGFloat = self.frame.size.width * 0.75
            let labelWidth = self.frame.size.width * 0.1
            let entryWidth = self.frame.size.width * 0.15
            let itemHeight = self.frame.size.height/3 - 2
            
            // Gradient Sliders
            for s in [hSlider, sSlider, bSlider] {
                s.frame.size.width = sliderWidth
                s.frame.size.height = itemHeight
                //s.hasRainbow = true
                s.minimumValue = 0.0
                s.maximumValue = 1.0
                s.value = 0.5
                s.addTarget(self, action: #selector(self.sliderValueDidChange), for: .valueChanged)
                s.addTarget(self, action: #selector(self.slidersDidEndChange), for: .touchUpInside) // may only need valueChanged ???
                addSubview(s)
            }
            hSlider.tintColor = UIColor.red
            sSlider.tintColor = UIColor.green
            bSlider.tintColor = UIColor.blue

            // Labels
            for label in [hLabel, sLabel, bLabel] {
                label.frame.size.width = labelWidth
                label.frame.size.height = itemHeight
                label.textAlignment = .left
                label.textColor = theme.textColor
                label.font = UIFont.systemFont(ofSize: 12.0)
                addSubview(label)
            }
            
            hLabel.text = "H: "
            sLabel.text = "S: "
            bLabel.text = "B: "

            // Text Entry
            // toolbar to dismiss keypad
            let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.frame.size.width, height: 30))
            let flexSpace = UIBarButtonItem(barButtonSystemItem:    .flexibleSpace, target: nil, action: nil)
            let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.textEditDoneAction))
            toolbar.setItems([flexSpace, doneBtn], animated: false)
            toolbar.sizeToFit()

            for entry in [hEntry, sEntry, bEntry] {
                entry.frame.size.width = entryWidth
                entry.frame.size.height = itemHeight
                entry.textAlignment = .left
                entry.textColor = theme.textColor
                entry.font = UIFont.systemFont(ofSize: 12.0)
                entry.keyboardType = UIKeyboardType.numberPad
                entry.inputAccessoryView = toolbar
                entry.delegate = self
                addSubview(entry)
            }
            // line up the sliders on the left
            hSlider.anchorInCorner(.topLeft, xPad: 2, yPad: 2, width: hSlider.frame.size.width, height: hSlider.frame.size.height)
            sSlider.align(.underMatchingRight, relativeTo: hSlider, padding: 2, width: sSlider.frame.size.width, height: sSlider.frame.size.height)
            bSlider.align(.underMatchingRight, relativeTo: sSlider, padding: 2, width: bSlider.frame.size.width, height: bSlider.frame.size.height)
            
            // add the labels and text entry items
            hLabel.align(.toTheRightCentered, relativeTo: hSlider, padding: 4, width: hLabel.frame.size.width, height: hLabel.frame.size.height)
            sLabel.align(.toTheRightCentered, relativeTo: sSlider, padding: 4, width: sLabel.frame.size.width, height: sLabel.frame.size.height)
            bLabel.align(.toTheRightCentered, relativeTo: bSlider, padding: 4, width: bLabel.frame.size.width, height: bLabel.frame.size.height)
            
            hEntry.align(.toTheRightCentered, relativeTo: hLabel, padding: 4, width: hEntry.frame.size.width, height: hEntry.frame.size.height)
            sEntry.align(.toTheRightCentered, relativeTo: sLabel, padding: 4, width: sEntry.frame.size.width, height: sEntry.frame.size.height)
            bEntry.align(.toTheRightCentered, relativeTo: bLabel, padding: 4, width: bEntry.frame.size.width, height: bEntry.frame.size.height)

        }
    }
    

    
    //MARK: - callbacks
    
    @objc func sliderValueDidChange(_ sender:GradientSlider!){
        updateFromSliders()
        //delegate?.colorChanged(currColor)
    }
    
    
    @objc func slidersDidEndChange(_ sender:GradientSlider!){
        updateFromSliders()
        if !currColor.matches(oldColor){
            oldColor = currColor
            delegate?.hsbColorChanged(currColor)
        }
    }
    
    
    @objc func textEditDoneAction() {
        self.endEditing(true)
    }
    
    // dismiss keyboard if user touches anywhere outside the keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }

}

///////////////////////
//MARK: Extensions
///////////////////////

// UITextFieldStuff

extension HSBSliderView: UITextInputTraits {
    
    // force the numeric keypad
    private var keyboardType: UIKeyboardType {
        get{
            return UIKeyboardType.numberPad
        }
    }
}

extension HSBSliderView: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateFromText()
    }
    
    func textField(_ textFieldToChange: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // limit to 4 characters
        let characterCountLimit = 2
        
        // We need to figure out how many characters would be in the string after the change happens
        let startingLength = textFieldToChange.text?.count ?? 0
        let lengthToAdd = string.count
        let lengthToReplace = range.length
        
        let newLength = startingLength + lengthToAdd - lengthToReplace
        
        return newLength <= characterCountLimit
    }
    
    private func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

