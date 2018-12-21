//
//  FilterParametersView.swift
//  phixer
//
//  Created by Philip Price on 10/6/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon


// Class responsible for laying out the Parameters associated with a filter

// Interface required of controlling View
protocol FilterParametersViewDelegate: class {
    func settingsChanged()
    func positionRequested(key:String)
    func commitChanges(key:String)
    func cancelChanges(key:String)
}


class FilterParametersView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    public var numVisibleParams:Int = 0

    //var isLandscape : Bool = false
    
    var currFilterDesc: FilterDescriptor? = nil

    
    var initDone: Bool = false
    
    let sliderHeight: Float = 32.0
    
    var showControls:Bool = true

    // display items
    
    var titleLabel:UILabel! = UILabel()
    var titleView: UIView! = UIView()
    var parameterView: UIView! = UIView()
    var scrollView: UIScrollView? = nil
    
    var acceptButton: SquareButton? = nil
    var cancelButton: SquareButton? = nil

    
    var sliders: [UIView] = []
    
    var viewList:[UIView] = []
    
    var pKey:[String] = []
    
    // Colours

    lazy var titleBackgroundColor:UIColor = theme.subtitleColor
    lazy var titleTextColor:UIColor = theme.subtitleTextColor
    lazy var buttonBackgroundColor:UIColor = theme.highlightColor
    lazy var buttonTextColor:UIColor = theme.titleTextColor
    lazy var viewBackgroundColor:UIColor = theme.backgroundColor
    lazy var sliderTextColor:UIColor = theme.textColor

    
    // delegate for handling events
    weak var delegate: FilterParametersViewDelegate?
    
    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    // enables/disabled 'confirm' mode, where user has to explicitly Accept changes
    public func setConfirmMode(_ confirm:Bool){
        self.showControls = confirm
    }
   

    
    fileprivate func initViews(){
        
        //if (!initDone && (currFilterDesc != nil)){
        if (currFilterDesc != nil){
            
            //self.backgroundColor = UIColor.flatGray()
            self.backgroundColor = viewBackgroundColor
            self.alpha = 0.9
            
            viewList = []
            
           
            //self.frame.size.width = self.frame.size.width - 16.0
            // height: title + sliders + buttons (or not)
            var f1, f2: CGFloat

            f1 = 1.6*CGFloat((currFilterDesc?.getNumDisplayableParameters())!) + 1.6
            f2 = CGFloat(sliderHeight)
            self.frame.size.height = max((f1 * f2).rounded(), 3*f2)
            
            if (scrollView == nil) {
                var frame = self.frame
                frame.size.height = frame.size.height - titleView.frame.size.height
                scrollView = UIScrollView(frame: frame)
            }
            
            initDone = true
        }
    }
    
    
    fileprivate func layoutTitle(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        // if controls requested then add to title bar
        
        if self.showControls {
            acceptButton = SquareButton(bsize: CGFloat(sliderHeight)*0.8)
            acceptButton?.setImageAsset("ic_yes")
            acceptButton?.backgroundColor = theme.subtitleColor.withAlphaComponent(0.8)
            acceptButton?.setTintable(true)
            acceptButton?.highlightOnSelection(true)
            acceptButton?.addTarget(self, action: #selector(self.acceptDidPress), for: .touchUpInside)
            
            cancelButton = SquareButton(bsize: CGFloat(sliderHeight)*0.8)
            cancelButton?.setImageAsset("ic_no")
            cancelButton?.backgroundColor = theme.subtitleColor.withAlphaComponent(0.8)
            cancelButton?.setTintable(true)
            cancelButton?.highlightOnSelection(true)
            cancelButton?.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)

            titleView.addSubview(acceptButton!)
            titleView.addSubview(cancelButton!)

        }

        
        titleLabel.frame.size.width = (self.frame.size.width/3.0).rounded()
        titleLabel.frame.size.height = (CGFloat(sliderHeight*0.8)).rounded()
        titleLabel.textColor = titleTextColor
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.text = currFilterDesc?.title
        titleLabel.textAlignment = .center
        
        titleView.frame.size.width = (self.frame.size.width - 6.0).rounded()
        titleView.frame.size.height = CGFloat(sliderHeight*0.9).rounded()
        titleView.backgroundColor = titleBackgroundColor
        
        titleView.addSubview(titleLabel)
        
        //TODO: add left/right buttons to move between filters (and the interface to tell the view controller
        
        self.addSubview(titleView)

        if self.showControls {
            acceptButton?.anchorToEdge(.left, padding: 2, width: (acceptButton?.frame.size.width)!, height: (acceptButton?.frame.size.height)!)
            cancelButton?.anchorToEdge(.right, padding: 0, width: (cancelButton?.frame.size.width)!, height: (cancelButton?.frame.size.height)!)
            titleLabel.alignBetweenHorizontal(align: .toTheRightCentered, primaryView: acceptButton!, secondaryView: cancelButton!, padding: 2, height: AutoHeight)
        } else {
            titleLabel.fillSuperview()
        }
        
        log.verbose("Filter Title: \(String(describing: currFilterDesc?.title)) h:\(titleLabel.frame.size.height) w:\(titleLabel.frame.size.width)")
    }
  
   

    fileprivate var gsliders: [GradientSlider?] = []

    fileprivate func layoutParameters(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        var pConfig: FilterDescriptor.ParameterSettings
        var slider: UISlider?
        var label: UILabel
        var pView: UIView
        var currColor: UIColor = UIColor.blue
        
        log.verbose("Laying out parameters...")
        sliders = []
        gsliders = []
        pKey = []
        numVisibleParams = 0
        var i:Int
        i = 0
        for key in (currFilterDesc?.getParameterKeys())!{
            pConfig = (currFilterDesc?.getParameterSettings(key))!
            if (pConfig.type == FilterDescriptor.ParameterType.float) ||
                (pConfig.type == FilterDescriptor.ParameterType.color) ||
                (pConfig.type == FilterDescriptor.ParameterType.position) {

                
                pView = UIView()
                pView.frame.size.width = self.frame.size.width
                pView.frame.size.height = CGFloat(sliderHeight*1.25)
                
                label = UILabel()
                label.text = pConfig.title
                label.frame.size.width = self.frame.size.width/3.0
                label.frame.size.height = CGFloat(sliderHeight/2.0)
                //label.textAlignment = .center
                label.textAlignment = .left
                label.textColor = sliderTextColor
                label.font = UIFont.systemFont(ofSize: 12.0)
                pView.addSubview(label)
                
                switch pConfig.type {
                case  FilterDescriptor.ParameterType.float:
                    slider = UISlider()
                    slider?.minimumValue = pConfig.min
                    slider?.maximumValue = pConfig.max
                    var value = currFilterDesc?.getParameter(key)
                    if (value == FilterDescriptor.parameterNotSet){ value = pConfig.value }
                    slider?.value = value!
                    //log.verbose("value: \(value!)")
                    log.verbose("...(\(pConfig.title), \(pConfig.min)..\(pConfig.max), def:\(pConfig.value)) val: \(value!)")
                   slider?.tag = i // let slider know the parameter order
                    //pKey[i] = key
                    pKey.append(key)
                    slider?.isHidden = false
                    slider?.setNeedsUpdateConstraints()
                    slider?.frame.size.width = self.frame.size.width
                    slider?.frame.size.height = CGFloat(sliderHeight*0.8).rounded()
                    
                    attachSliderAction(slider!)
                    pView.addSubview(slider!)
                     //TODO: add labels for: min, max, current value (?)
                    
                    pView.groupAndFill(group: .vertical, views: [label, slider!], padding: 4.0)
                    
                case FilterDescriptor.ParameterType.color:
                    // RGB Slider, need to deal with colors
                    //log.debug("Gradient Slider requested")
                    log.verbose("...(\(pConfig.title) (colour)")
                    
                    let gslider = GradientSlider()
                    gslider.hasRainbow = true
                    //gslider.setValue(value: 0.5) // middle colour
                    let c = self.currFilterDesc?.getColorParameter(key)
                    gslider.setValue(hueFromColor(c)) // default for class
                    gslider.tag = i // let slider know the parameter order
                    //pKey[i] = key
                    pKey.append(key)
                    gslider.isHidden = false
                    gslider.setNeedsUpdateConstraints()
                    gslider.frame.size.width = self.frame.size.width
                    gslider.frame.size.height = CGFloat(sliderHeight*0.8).rounded()
                    
                    // figure out current saturation & brightness
                    var currHue = CGFloat(1.0)
                    var currSat = CGFloat(1.0)
                    var currBright = CGFloat(1.0)
                    var currAlpha = CGFloat(1.0)
                    if c != nil {
                        UIColor(ciColor: c!).getHue(&currHue, saturation: &currSat, brightness: &currBright, alpha: &currAlpha)
                    }

                    
                    gslider.setGradientForHueWithSaturation(currSat,brightness:currBright)
                    gslider.actionBlock = { slider, value in
                        
                        //First disable animations so we get instantaneous updates
                        CATransaction.begin()
                        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
                        
                        //Update the thumb color to match the new value
                        currColor = UIColor(hue: value, saturation: currSat, brightness: currBright, alpha: 1.0)
                        slider.thumbColor = currColor
                        
                        CATransaction.commit()
                        self.currFilterDesc?.setColorParameter(key, color: CIColor(color: currColor))
                    }
                    //attachColorSliderAction(gsliders[i]!)
                    gsliders.append(gslider)
                    pView.addSubview(gslider)
                    pView.groupAndFill(group: .vertical, views: [label, gslider], padding: 2.0)
                    
                case FilterDescriptor.ParameterType.position:
                    log.verbose("...(\(pConfig.title) (position)")
                    let touchButton = SquareButton(bsize: CGFloat(sliderHeight)*0.8)
                    
                    touchButton.setImageAsset("ic_touch")
                    touchButton.setTintable(true)
                    touchButton.highlightOnSelection(true)
                    touchButton.addTarget(self, action: #selector(self.touchDidPress), for: .touchUpInside)
                    touchButton.setTag(i) // let button know the parameter order
                    pKey.append(key)
                    pView.addSubview(touchButton)
                    pView.groupAndFill(group: .horizontal, views: [label, touchButton], padding: 8.0)

                default:
                    log.error("Invalid parameter type: \(pConfig.type)")
               }
                
                sliders.append(pView)
                parameterView.addSubview(pView)
                numVisibleParams = numVisibleParams + 1
                i = i + 1
            }
        }
        
        scrollView?.addSubview(parameterView)
        self.addSubview(scrollView!)

    }
    
    
    
    // Attaches an action handler based on the slider index
    fileprivate func attachSliderAction(_ slider:UISlider){

        slider.addTarget(self, action: #selector(self.sliderValueDidChange), for: .valueChanged)
        
        // shared callback for when user ends changing any slider (intended as an update trigger, don't need the value)
        slider.addTarget(self, action: #selector(self.slidersDidEndChange), for: .touchUpInside)
    }
    
    
    
    // Attaches an action handler based on the slider index
    fileprivate func attachColorSliderAction(_ gslider:GradientSlider){
        
        gslider.addTarget(self, action: #selector(self.colorSliderValueDidChange), for: .valueChanged)
       
        // shared callback for when user ends changing any slider (intended as an update trigger, don't need the value)
        gslider.addTarget(self, action: #selector(self.gslidersDidEndChange), for: .touchUpInside)
    }
    
    
    
    // layout is a bit complicated due to options and a variable number of parameters, so call this after everything else has been set up
    fileprivate func finishLayout(){
        // add the views to the list in the order of display

        var height:CGFloat = 0.0
        
        // calculate sizes (need to this before setting constraints)
        height = titleView.frame.size.height
        if ((currFilterDesc?.getNumDisplayableParameters())! > 0){
            let n:CGFloat = CGFloat(numVisibleParams)
            let h:CGFloat =  (CGFloat(sliderHeight) * n*1.3).rounded() // empirical
            parameterView.frame.size.width = titleView.frame.size.width
            parameterView.frame.size.height = h
            scrollView?.contentSize = parameterView.frame.size
            height = height + parameterView.frame.size.height
        } else {
            parameterView.frame.size.width = titleView.frame.size.width
            parameterView.frame.size.height = 0
            scrollView?.frame.size.height = 0
            scrollView?.contentSize = CGSize.zero
        }

        self.frame.size.height = height
        self.anchorToEdge(.bottom, padding: 1, width: self.frame.size.width, height: self.frame.size.height)

        //DEBUG
        /***
        log.debug("\(numVisibleParams) params\n" +
                  "T:[w:\(titleView.frame.size.width), h:\(titleView.frame.size.height)]\n" +
                  "P:[w:\(parameterView.frame.size.width), h:\(parameterView.frame.size.height)]\n" +
                  "S:[w:\(scrollView?.contentSize.width), h:\(scrollView?.contentSize.height)]\n" +
                  "A:[w:\(self.frame.size.width), h:\(self.frame.size.height)]" )
        ***/

        // layout sub-views
        
        // Place the tile at the top, buttons at the bottom and sliders distributed in between
        titleView.anchorAndFillEdge(.top, xPad: 2.0, yPad: 2.0, otherSize: titleView.frame.size.height)

        if ((currFilterDesc?.getNumDisplayableParameters())! > 0){
            parameterView.groupAndFill(group: .vertical, views: sliders, padding: 2.0)
            scrollView?.alignAndFill(align: .underCentered, relativeTo: titleView, padding: 0, offset: 0)
        }
    }
    
    
    
    fileprivate func clearSubviews(){
        for v in parameterView.subviews{
            v.removeFromSuperview()
        }
        if (scrollView != nil){
            for v in (scrollView?.subviews)!{
                v.removeFromSuperview()
            }
        }
        for v in self.subviews{
            v.removeFromSuperview()
        }
    }
    
    
    fileprivate func layoutUI(){
        clearSubviews()
        self.isHidden = false
        initViews()
        layoutTitle()
        layoutParameters()
        finishLayout()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // don't do anything until filter is set
    }
    
    
    open func dismiss(){
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0 }) { _ in
            self.clearSubviews()
            self.isHidden = true
            //self.removeFromSuperview()
        }
    }
    
    open func setFilter(_ descriptor:FilterDescriptor?){
        
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
    
    func updateFilterTargets(){
        //TODO: how to force UI update on filtered image???
    }
    
    
    
    // get the hue value (0.0-1.0) from a Color type
    fileprivate func hueFromColor(_ color:CIColor?)->CGFloat{
        
        var h:CGFloat = 0.0
        var s:CGFloat = 0.0
        var l:CGFloat = 0.0
        var a:CGFloat = 1.0
        var c: UIColor
        
        if (color == nil){
            c = UIColor.blue
        } else {
            c = UIColor(ciColor: color!)
        }
        
        c.getHue(&h, saturation: &s, brightness: &l, alpha: &a)
        return h
    }

    
    //////////////////////////////
    //MARK: - touch handlers
    //////////////////////////////

    @objc func acceptDidPress() {
        
        // value is set as sliders are moved, so no need to do anything except clean up and return
        delegate?.commitChanges(key: (currFilterDesc?.key)!)
        dismiss()
    }
    
    @objc func defaultDidPress(){
        currFilterDesc?.reset()
        layoutUI()
   }
    
    @objc func cancelDidPress(){
        // restore saved parameters
        currFilterDesc?.restoreParameters()
        delegate?.cancelChanges(key:  (currFilterDesc?.key)!)
        dismiss()
    }
    
    @objc func sliderValueDidChange(_ sender:UISlider!){
        currFilterDesc?.setParameter(pKey[sender.tag], value: sender.value)
        delegate?.settingsChanged()
    }
    
    
    @objc func colorSliderValueDidChange(_ sender:GradientSlider!){
        let index = sender.tag
        currFilterDesc?.setColorParameter(pKey[index], color: CIColor(color: (gsliders[index]?.getSelectedColor())!))
    }
    
    @objc func slidersDidEndChange(_ sender:UISlider!){
        log.verbose("Settings changed for slider \(pKey[sender.tag])")
        currFilterDesc?.setParameter(pKey[sender.tag], value: sender.value)
        delegate?.settingsChanged()
    }
    
    @objc func gslidersDidEndChange(_ sender:GradientSlider!){
        let index = sender.tag
        log.verbose("Settings changed for color slider \(pKey[index])")
        currFilterDesc?.setColorParameter(pKey[index], color: CIColor(color: (gsliders[index]?.getSelectedColor())!))
        delegate?.settingsChanged()
    }
    

    
    @objc func touchDidPress(sender: UIButton!) {
        let index = sender.tag

        log.verbose("Touch pressed for: \(pKey[index])")
        if delegate != nil {
            delegate?.positionRequested(key:pKey[index])
        } else {
            log.warning("No delegate")
        }
    }

}
