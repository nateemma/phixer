//
//  FilterSettingsView.swift
//  FilterCam
//
//  Created by Philip Price on 10/6/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
//
//  CameraInfoView.swift
//  Philter
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import Neon


// Class responsible for laying out the Camera Information View
// This is a container class for display the overlay that provides information about the current Camera/Image view

// Interface required of controlling View
//protocol FilterSettingsViewDelegate: class {
//    func updateFilterSettings(value1:Float, value2:Float,  value3:Float,  value4:Float)
//}


class FilterSettingsView: UIView {
    
    //var isLandscape : Bool = false
    
    var currFilterDesc: FilterDescriptorInterface? = nil
    
    var initDone: Bool = false
    
    let sliderHeight: Float = 48.0

    // display items
    
    var titleLabel:UILabel! = UILabel()
    var titleView: UIView! = UIView()

    var acceptButton: UIButton! = UIButton()
    var cancelButton: UIButton! = UIButton()
    var buttonContainerView: UIView! = UIView()
    
    var sliders: [UIView] = []
    
    var viewList:[UIView] = []
    
    
    // delegate for handling events
    //weak var delegate: FilterSettingsViewDelegate?
    
    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initButton(_ button: UIButton){
        button.backgroundColor = UIColor.flatPowderBlueColorDark()
        button.titleLabel?.textColor = UIColor.flatWhite()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.titleLabel?.textAlignment = .center
        button.frame.size.height = CGFloat(sliderHeight - 4.0)
    }
    
    
    
    func initViews(){
        
        //if (!initDone && (currFilterDesc != nil)){
        if (currFilterDesc != nil){
            
            self.backgroundColor = UIColor.flatGray()
            self.alpha = 0.9
            
            viewList = []
            
            self.frame.size.width = self.superFrame.size.width - 16.0
            let f1: CGFloat = 2.0*CGFloat((currFilterDesc?.numSliders)!) + 2.0
            let f2: CGFloat = CGFloat(sliderHeight)
            self.frame.size.height = f1 * f2
            layoutButtons()
            
            initDone = true
        }
    }
    
    
    func layoutTitle(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        titleLabel.frame.size.width = self.superFrame.size.width/3.0
        titleLabel.frame.size.height = CGFloat(sliderHeight*0.75)
        //titleLabel.textColor = UIColor.flatWhite()
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.text = currFilterDesc?.title
        titleLabel.textAlignment = .center
        
        titleView.frame.size.width = self.superFrame.size.width - 16.0
        titleView.frame.size.height = CGFloat(sliderHeight*0.8)
        titleView.backgroundColor = UIColor.flatPowderBlue()
        titleView.addSubview(titleLabel)
        
        //TODO: add left/right buttons to move between filters (and the interface to tell the view controller
        
        self.addSubview(titleView)

        //titleLabel.anchorInCenter(CGFloat(self.frame.size.width-8.0), height: CGFloat(sliderHeight))
        titleLabel.fillSuperview()
        
        log.verbose("Filter Title: \(currFilterDesc?.title) h:\(titleLabel.frame.size.height) w:\(titleLabel.frame.size.width)")
    }
  
    
    func layoutButtons(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        // TODO: "Reset" button
        
        initButton(acceptButton)
        acceptButton.setTitle("Accept", for: .normal)
        
        initButton(cancelButton)
        cancelButton.setTitle("Cancel", for: .normal)
        
        
        buttonContainerView.addSubview(acceptButton)
        buttonContainerView.addSubview(cancelButton)
        
        buttonContainerView.frame.size.width = self.superFrame.size.width
        buttonContainerView.frame.size.height = CGFloat(sliderHeight)
        
        self.addSubview(buttonContainerView)
        
        let pad = self.frame.size.width / 9
        buttonContainerView.groupAndFill(.horizontal, views: [acceptButton, cancelButton], padding: pad)

        
        // register handlers for the buttons
        acceptButton.addTarget(self, action: #selector(self.acceptDidPress), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)

    }
    
 
    func layoutSliders(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        var sliderConfig: ParameterSettings
        var slider: UISlider
        var label: UILabel
        var sliderView: UIView
        
        log.verbose("Laying out sliders...")
        sliders = []
        if ((currFilterDesc?.numSliders)! > 0){
            for i in 1 ... (currFilterDesc?.numSliders)!{
                sliderConfig = (currFilterDesc?.parameterConfiguration[i-1])!
                
                log.verbose("...(\(sliderConfig.title), \(sliderConfig.minimumValue), \(sliderConfig.maximumValue), \(sliderConfig.initialValue))")
                
                sliderView = UIView()
                sliderView.frame.size.width = self.frame.size.width
                sliderView.frame.size.height = CGFloat(sliderHeight*1.5)
                
                label = UILabel()
                label.text = sliderConfig.title
                label.frame.size.width = self.frame.size.width/3.0
                label.frame.size.height = CGFloat(sliderHeight/2.0)
                label.textAlignment = .center
                sliderView.addSubview(label)
                
                slider = UISlider()
                slider.minimumValue = sliderConfig.minimumValue
                slider.maximumValue = sliderConfig.maximumValue
                var value = currFilterDesc?.getParameter(index: i)
                if (value == parameterNotSet){ value = sliderConfig.initialValue }
                slider.value = value!
                slider.tag = i // let slider know the parameter order
                slider.isHidden = false
                slider.setNeedsUpdateConstraints()
                slider.frame.size.width = self.frame.size.width
                slider.frame.size.height = CGFloat(sliderHeight*0.75)
                attachSliderAction(slider)
                sliderView.addSubview(slider)
                
                //TODO: add bounds, current value
                
                sliderView.groupAndFill(.vertical, views: [label, slider], padding: 2.0)
                
                sliders.append(sliderView)
                self.addSubview(sliderView)
            }
        }
        
        
    }
    
    // Attaches an action handler based on the slider index
    func attachSliderAction(_ slider:UISlider){
        let index = slider.tag
        switch (index){
        case 1:
            slider.addTarget(self, action: #selector(self.slider1ValueDidChange), for: .valueChanged)
            break
        case 2:
            slider.addTarget(self, action: #selector(self.slider2ValueDidChange), for: .valueChanged)
            break
        case 3:
            slider.addTarget(self, action: #selector(self.slider3ValueDidChange), for: .valueChanged)
            break
        case 4:
            slider.addTarget(self, action: #selector(self.slider4ValueDidChange), for: .valueChanged)
            break
        default:
            log.error("Invalid slider index: \(index)")
            break
        }
    }
    

    func finishLayout(){
        // add the views to the list in the order of display
/***
        viewList = []
        // Title
        viewList.append(titleView)
        //viewList.append(titleLabel)
        
        // Sliders
        for i in 1 ... (currFilterDesc?.numSliders)!{
            viewList.append(sliders[i-1])
        }
        
        // Buttons
        viewList.append(buttonContainerView)
        self.groupAndFill(.vertical, views: viewList, padding: 2.0)
         
         //self.groupInCenter(.vertical, views: viewList, padding: 2.0, width: self.frame.size.width, height: self.frame.size.height)

 ***/
        
/***/
        // Place the tile at the top, buttons at the bottom and sliders distributed in between
        titleView.anchorAndFillEdge(.top, xPad: 2.0, yPad: 2.0, otherSize: titleView.frame.size.height)
        buttonContainerView.anchorAndFillEdge(.bottom, xPad: 2.0, yPad: 2.0, otherSize: buttonContainerView.frame.size.height)
        if ((currFilterDesc?.numSliders)! > 0){
            self.groupInCenter(.vertical, views: sliders, padding: 2.0, width: sliders[0].frame.size.width, height: sliders[0].frame.size.height)
        }

/***
        if ((currFilterDesc?.numSliders)! > 0){
            sliders[0].align(.underCentered, relativeTo: titleView, padding: 2.0, width: 2.0, height: sliders[0].frame.size.height)
            if ((currFilterDesc?.numSliders)! > 1){
                for i in 2 ... (currFilterDesc?.numSliders)!{
                    sliders[i-1].align(.underMatchingLeft, relativeTo: sliders[i-2], padding: 2.0, width: 2.0, height: sliders[i-1].frame.size.height)
                }
            }
        }
 ***/
    }
    
    
    func clearSubviews(){
        for v in self.subviews{
            v.removeFromSuperview()
        }
    }
    
    
    func layoutUI(){
        clearSubviews()
        self.isHidden = false
        initViews()
        layoutTitle()
        layoutSliders()
        layoutButtons()
        finishLayout()
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // don't do anything until filter is set
    }
    
    
    func setFilter(_ descriptor:FilterDescriptorInterface?){
        
        // if no filter then clear sub-views and hide view, otherwise re-build based on the filter descriptor
        if (descriptor == nil)  {
            clearSubviews()
            self.isHidden = false
        } else {
            
            currFilterDesc = descriptor
            currFilterDesc?.stashParameters() // save initial values in case the user cancels
            
            layoutUI()
        }
    }
    
    
    
    //MARK: - touch handlers
    
    func acceptDidPress() {
        /*
        var value1:Float = 0.0
        var value2:Float = 0.0
        var value3:Float = 0.0
        var value4:Float = 0.0
        
        if ((currFilterDesc?.numSliders)!>0){
        
            if ((currFilterDesc?.numSliders)! >= 1){ value1 = sliders[0].value }
            if ((currFilterDesc?.numSliders)! >= 2){ value2 = sliders[1].value }
            if ((currFilterDesc?.numSliders)! >= 3){ value3 = sliders[2].value }
            if ((currFilterDesc?.numSliders)! >= 4){ value4 = sliders[3].value }
            
            delegate?.updateFilterSettings(value1: value1, value2: value2,  value3: value3,  value4: value4)
         }
        */
        
        // value is set as sliders are moved, so no need to do anything except clean up and return
        clearSubviews()
        self.isHidden = true
    }
    
    func cancelDidPress(){
        // restore saved parameters
        currFilterDesc?.restoreParameters()
        clearSubviews()
        self.isHidden = true
    }
    
    func slider1ValueDidChange(sender:UISlider!){
        currFilterDesc?.setParameter(index: 1, value: sender.value)
    }
    
    func slider2ValueDidChange(sender:UISlider!){
        currFilterDesc?.setParameter(index: 2, value: sender.value)
    }
    
    func slider3ValueDidChange(sender:UISlider!){
        currFilterDesc?.setParameter(index: 3, value: sender.value)
    }
    
    func slider4ValueDidChange(sender:UISlider!){
        currFilterDesc?.setParameter(index: 4, value: sender.value)
    }
}
