//
//  RGBSliderView.swift
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
protocol RGBSliderViewDelegate: class {
    func rgbColorChanged(_ color:UIColor)
}


class RGBSliderView: UIView {

    
    var theme = ThemeManager.currentTheme()
    

    var initDone: Bool = false
    
    let sliderHeight: CGFloat = 32.0
    
    // RGB display items
    let rSlider:GradientSlider = GradientSlider()
    let gSlider:GradientSlider = GradientSlider()
    let bSlider:GradientSlider = GradientSlider()
    let rLabel:UILabel = UILabel()
    let gLabel:UILabel = UILabel()
    let bLabel:UILabel = UILabel()
    let rEntry:UITextField = UITextField()
    let gEntry:UITextField = UITextField()
    let bEntry:UITextField = UITextField()

    // Colour values
    var rValue:CGFloat = 0.0
    var gValue:CGFloat = 0.0
    var bValue:CGFloat = 0.0
    var aValue:CGFloat = 1.0
    lazy var currColor:UIColor = theme.backgroundColor
    lazy var oldColor:UIColor = theme.backgroundColor

    // delegate for notification
    weak var delegate: RGBSliderViewDelegate?

    
    public func setColor(_ color:UIColor){
        currColor = color
        color.getRed(&rValue, green: &gValue, blue: &bValue, alpha: &aValue)
        rSlider.setValue(rValue, animated: false)
        gSlider.setValue(gValue, animated: false)
        bSlider.setValue(bValue, animated: false)
        
        updateFromSliders()
        oldColor = currColor // save for later comparison
    }
    

    
    
    convenience init(){
        self.init(frame: CGRect.zero)
        
        initDone = false
        
        // don't do anything until the color has been set
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
        rValue = truncate(CGFloat(rSlider.value), to:1000)
        gValue = truncate(CGFloat(gSlider.value), to:1000)
        bValue = truncate(CGFloat(bSlider.value), to:1000)
        currColor = UIColor(red: rValue, green: gValue, blue: bValue, alpha: 1.0)
        rEntry.text = String(format:"%3d",Int(rValue*255))
        gEntry.text = String(format:"%3d",Int(gValue*255))
        bEntry.text = String(format:"%3d",Int(bValue*255))
        rSlider.setGradientForRedWithGreen(gValue, blue: bValue)
        gSlider.setGradientForGreenWithRed(rValue, blue: bValue)
        bSlider.setGradientForBlueWithRed(rValue, green: gValue)
        log.debug("r:\(rValue) g:\(gValue) b:\(bValue)")
    }
    
    // get values from text and update associated values
    func updateFromText(){
        rValue = truncate(CGFloat(Int(rEntry.text!)!) / 255.0, to:1000)
        gValue = truncate(CGFloat(Int(gEntry.text!)!) / 255.0, to:1000)
        bValue = truncate(CGFloat(Int(bEntry.text!)!) / 255.0, to:1000)
        log.debug("r:\(rValue) g:\(gValue) b:\(bValue)")
        currColor = UIColor(red: rValue, green: gValue, blue: bValue, alpha: 1.0)
        rSlider.value = rValue
        gSlider.value = gValue
        bSlider.value = bValue
        rSlider.setGradientForRedWithGreen(gValue, blue: bValue)
        gSlider.setGradientForGreenWithRed(rValue, blue: bValue)
        bSlider.setGradientForBlueWithRed(rValue, green: gValue)
        rSlider.setNeedsDisplay()
        gSlider.setNeedsDisplay()
        bSlider.setNeedsDisplay()
    }

   
    fileprivate func truncate(_ val:CGFloat, to:Int) -> CGFloat{
        return round (val * CGFloat(to)) / CGFloat(to)
    }

    fileprivate func initViews(){
        
        //if (!initDone && (currFilterDesc != nil)){
        if (!initDone){
            initDone = true
            
            self.backgroundColor = UIColor.clear
            
            let sliderWidth:CGFloat = self.frame.size.width * 0.75
            let labelWidth = min(32, self.frame.size.width * 0.05)
            let entryWidth = min(32, self.frame.size.width * 0.1)
            let itemHeight = self.frame.size.height/3 - 2
            
            // Sliders
            for s in [rSlider, gSlider, bSlider] {
                s.frame.size.width = sliderWidth
                s.frame.size.height = itemHeight
                s.minimumValue = 0.0
                s.maximumValue = 1.0
                s.trackBorderWidth = 0.01
                s.addTarget(self, action: #selector(self.sliderValueDidChange), for: .valueChanged)
                s.addTarget(self, action: #selector(self.slidersDidEndChange), for: .touchUpInside) // may only need valueChanged ???
                addSubview(s)
            }


            // Labels
            for label in [rLabel, gLabel, bLabel] {
                label.frame.size.width = labelWidth
                label.frame.size.height = itemHeight
                label.textAlignment = .left
                label.textColor = theme.textColor
                label.font = UIFont.systemFont(ofSize: 12.0)
                addSubview(label)
            }
            
            rLabel.text = "R: "
            gLabel.text = "G: "
            bLabel.text = "B: "

            // Text Entry
            // toolbar to dismiss keypad
            let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.frame.size.width, height: 30))
            let flexSpace = UIBarButtonItem(barButtonSystemItem:    .flexibleSpace, target: nil, action: nil)
            let doneBtn: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.textEditDoneAction))
            toolbar.setItems([flexSpace, doneBtn], animated: false)
            toolbar.sizeToFit()

            for entry in [rEntry, gEntry, bEntry] {
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
             rSlider.anchorInCorner(.topLeft, xPad: 2, yPad: 2, width: rSlider.frame.size.width, height: rSlider.frame.size.height)
             gSlider.align(.underMatchingRight, relativeTo: rSlider, padding: 2, width: rSlider.frame.size.width, height: rSlider.frame.size.height)
             bSlider.align(.underMatchingRight, relativeTo: gSlider, padding: 2, width: rSlider.frame.size.width, height: rSlider.frame.size.height)
             
             // add the labels and text entry items
             rLabel.align(.toTheRightCentered, relativeTo: rSlider, padding: 4, width: rLabel.frame.size.width, height: rLabel.frame.size.height)
             gLabel.align(.toTheRightCentered, relativeTo: gSlider, padding: 4, width: gLabel.frame.size.width, height: gLabel.frame.size.height)
             bLabel.align(.toTheRightCentered, relativeTo: bSlider, padding: 4, width: bLabel.frame.size.width, height: bLabel.frame.size.height)
             
             rEntry.align(.toTheRightCentered, relativeTo: rLabel, padding: 4, width: rEntry.frame.size.width, height: rEntry.frame.size.height)
             gEntry.align(.toTheRightCentered, relativeTo: gLabel, padding: 4, width: gEntry.frame.size.width, height: gEntry.frame.size.height)
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
            delegate?.rgbColorChanged(currColor)
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

extension RGBSliderView: UITextInputTraits {
    
    // force the numeric keypad
    private var keyboardType: UIKeyboardType {
        get{
            return UIKeyboardType.numberPad
        }
    }
}

extension RGBSliderView: UITextFieldDelegate {
    
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

