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
    func fullScreenRequested()
    func splitScreenrequested()
    func showFiltersRequested()
    func showOriginalRequested()
}


class FilterParametersView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    public var numVisibleParams:Int = 0

    //var isLandscape : Bool = false
    
    var currFilterDesc: FilterDescriptor? = nil

    
    var initDone: Bool = false
    
    let sliderHeight: Float = 38.0
    
    var showControls:Bool = true

    // display items
    
    var titleLabel:UILabel! = UILabel()
    var titleView: UIView! = UIView()
    var parameterView: UIView! = UIView()
    var scrollView: UIScrollView? = nil
    
    var acceptButton: SquareButton? = nil
    var cancelButton: SquareButton? = nil
    var screenModeButton: SquareButton? = nil
    var filterModeButton: SquareButton? = nil

    
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
    
    // display mode vars
    var fullScreenEnabled:Bool = true
    var showFiltersEnabled:Bool = true
    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    //////////////////////////////
    // Accessors
    //////////////////////////////

    // enables/disabled 'confirm' mode, where user has to explicitly Accept changes
    public func setConfirmMode(_ confirm:Bool){
        self.showControls = confirm
    }
   
    
    
    //////////////////////////////
    // Accessors
    //////////////////////////////
 
    private var savedColor:UIColor? = UIColor.clear

    // Collapses the detail part of the view, leaving just the title bar
    public func collapse(){
        if initDone {
            
            /****/

            savedColor = self.backgroundColor
            self.backgroundColor = UIColor.clear
            self.scrollView?.isHidden = true
            /***/
        }
    }
    
    
    // Expands the detail part
    public func expand(){
        if initDone {
            self.backgroundColor = savedColor
            if self.numVisibleParams > 0 {
                self.scrollView?.isHidden = false
                self.scrollView?.canCancelContentTouches = false
            }
        } else {
            log.error("ERRR: init not done")
        }
    }
    
    
    public func dismiss(){
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0 }) { _ in
                self.clearSubviews()
                self.isHidden = true
                //self.removeFromSuperview()
        }
    }
    
    public func setFilter(_ descriptor:FilterDescriptor?){

        // if no filter then clear sub-views and hide view, otherwise re-build based on the filter descriptor
        //clearSubviews()
        if (descriptor != nil)  {
            
            currFilterDesc = descriptor
            currFilterDesc?.stashParameters() // save initial values in case the user cancels
            
            layoutUI()
            
            logSizes()

        } else {
            log.error("NIL filter descriptor supplied")
        }
    }

    //////////////////////////////
    // Init
    //////////////////////////////
    

    
    fileprivate func initViews(){
  

        //if (!initDone && (currFilterDesc != nil)){
        //if (currFilterDesc != nil){
        
        clearSubviews()
        
            self.backgroundColor = viewBackgroundColor.withAlphaComponent(0.6)
            //self.alpha = 0.9
            
            viewList = []
            fullScreenEnabled = true
            showFiltersEnabled = true
        
        // generate each time, otherwise stuff hangs around

        titleLabel = UILabel()
        titleView = UIView()
        parameterView = UIView()
        scrollView = nil
        
            //self.frame.size.width = self.frame.size.width - 16.0
            // height: title + sliders + buttons (or not)
            var f1, f2: CGFloat

            f1 = 1.6*CGFloat(currFilterDesc?.getNumDisplayableParameters() ?? 0) + 1.6
            f2 = CGFloat(sliderHeight)
            self.frame.size.height = max((f1 * f2).rounded(), 3*f2)
            
            if (scrollView == nil) {
                var frame = self.frame
                frame.size.height = frame.size.height - titleView.frame.size.height
                scrollView = UIScrollView(frame: frame)
            }
            
            initDone = true
        //}
    }
    
    
    fileprivate func layoutTitle(){
        
        
        // add control icons to title bar
        
        let side:CGFloat = CGFloat(sliderHeight)*0.8
        
        acceptButton = SquareButton(bsize: side)
        acceptButton?.setImageAsset("ic_yes")
        acceptButton?.addTarget(self, action: #selector(self.acceptDidPress), for: .touchUpInside)
        
        cancelButton = SquareButton(bsize: side)
        cancelButton?.setImageAsset("ic_no")
        cancelButton?.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)
        
        screenModeButton = SquareButton(bsize: side)
        if fullScreenEnabled {
            screenModeButton?.setImageAsset("ic_split_screen")
        } else {
            screenModeButton?.setImageAsset("ic_full_screen")
        }
        screenModeButton?.addTarget(self, action: #selector(self.screenModeDidPress), for: .touchUpInside)
        
        filterModeButton  = SquareButton(bsize: side)
        if showFiltersEnabled {
            filterModeButton?.setImageAsset("ic_no_view")
        } else {
            filterModeButton?.setImageAsset("ic_view")
        }
        filterModeButton?.addTarget(self, action: #selector(self.filterModeDidPress), for: .touchUpInside)
        
        for b in [acceptButton, cancelButton, screenModeButton, filterModeButton] {
            b?.backgroundColor = theme.subtitleColor.withAlphaComponent(0.8)
            b?.setTintable(true)
            b?.highlightOnSelection(true)
            titleView.addSubview(b!)
        }
        

        
        titleLabel.frame.size.width = (self.frame.size.width - 4.0*side).rounded()
        titleLabel.frame.size.height = (CGFloat(sliderHeight*0.8)).rounded()
        titleLabel.textColor = titleTextColor
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.text = currFilterDesc?.title ?? "No Filter"
        titleLabel.textAlignment = .center
        titleLabel.fitTextToBounds()
        titleView.addSubview(titleLabel)

        titleView.frame.size.width = (self.frame.size.width - 6.0).rounded()
        titleView.frame.size.height = CGFloat(sliderHeight*0.9).rounded()
        titleView.backgroundColor = titleBackgroundColor
        
        
        self.addSubview(titleView)

        acceptButton?.anchorToEdge(.left, padding: 2, width: (acceptButton?.frame.size.width)!, height: (acceptButton?.frame.size.height)!)
        cancelButton?.anchorToEdge(.right, padding: 0, width: (cancelButton?.frame.size.width)!, height: (cancelButton?.frame.size.height)!)
        screenModeButton?.align(.toTheRightCentered, relativeTo: acceptButton!, padding: 12, width: side, height: side)
        filterModeButton?.align(.toTheLeftCentered, relativeTo: cancelButton!, padding: 12, width: side, height: side)
        titleLabel.alignBetweenHorizontal(align: .toTheRightCentered, primaryView: screenModeButton!, secondaryView: filterModeButton!, padding: 2, height: AutoHeight)

        log.verbose("Filter Title: \(titleLabel.text) h:\(titleLabel.frame.size.height) w:\(titleLabel.frame.size.width)")
    }
  
   

    fileprivate var gsliders: [GradientSlider?] = []

    fileprivate func layoutParameters(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        var pConfig: ParameterSettings
        var slider: UISlider?
        var label: UILabel
        var textView: UIView
        var pView: UIView
        var currColor: UIColor = UIColor.blue
        
        log.verbose("Laying out parameters...")
        parameterView.backgroundColor = UIColor.clear
        scrollView?.backgroundColor = UIColor.clear
        sliders = []
        gsliders = []
        pKey = []
        numVisibleParams = 0
        var i:Int
        i = 0
        let plist = currFilterDesc?.getParameterKeys()
        
        if var plist = plist {
            if plist.count > 0 {
                plist.sort(by: { $0.localizedLowercase < $1.localizedLowercase })

                for key in plist {
                    pConfig = (currFilterDesc?.getParameterSettings(key))!
                    if (pConfig.type == ParameterType.float) ||
                        (pConfig.type == ParameterType.color) ||
                        (pConfig.type == ParameterType.position) {
                        
                        
                        pView = UIView()
                        pView.frame.size.width = self.frame.size.width
                        pView.frame.size.height = CGFloat(sliderHeight*1.25)
                        
                        textView = UIView()
                        textView.frame.size.width = self.frame.size.width
                        textView.frame.size.height = CGFloat(0.25)
                        textView.backgroundColor = UIColor.clear

                        label = UILabel()
                        label.backgroundColor = viewBackgroundColor
                        label.text = pConfig.title
                        label.frame.size.width = self.frame.size.width/3.0
                        label.frame.size.height = CGFloat(sliderHeight/2.0)
                        label.textAlignment = .left
                        label.textColor = sliderTextColor
                        label.font = UIFont.systemFont(ofSize: 12.0)
                        
                        // dynamically size label:
                        let newSize: CGSize = label.sizeThatFits(label.frame.size)
                        label.frame.size = newSize

                        textView.addSubview(label)
                        textView.anchorAndFillEdge(.left, xPad: 2, yPad: 0, otherSize: label.frame.size.width)
                        pView.addSubview(textView)
                        
                        switch pConfig.type {
                        case  ParameterType.float:
                            slider = UISlider()
                            slider?.minimumValue = pConfig.min
                            slider?.maximumValue = pConfig.max
                            var value = currFilterDesc?.getParameter(key)
                            if (value == FilterDescriptor.parameterNotSet){ value = pConfig.value }
                            slider?.value = value!
                            //log.verbose("value: \(value!)")
                            log.verbose("...\(pConfig.title): (\(pConfig.min)..\(pConfig.max), def:\(pConfig.value)) curr: \(value!)")
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
                            
                            pView.groupAndFill(group: .vertical, views: [textView, slider!], padding: 4.0)
                            
                        case ParameterType.color:
                            // RGB Slider, need to deal with colors
                            //log.debug("Gradient Slider requested")
                            log.verbose("...\(pConfig.title) (colour)")
                            
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
                            pView.groupAndFill(group: .vertical, views: [textView, gslider], padding: 2.0)
                            
                        case ParameterType.position:
                            let touchButton = SquareButton(bsize: CGFloat(sliderHeight))
                            touchButton.backgroundColor = viewBackgroundColor.withAlphaComponent(0.8)
                            
                            touchButton.setImageAsset("ic_touch")
                            touchButton.setTintable(true)
                            touchButton.highlightOnSelection(true)
                            
                            // assign touch hanlder to icon
                            touchButton.addTarget(self, action: #selector(self.touchDidPress), for: .touchUpInside)
                            touchButton.setTag(i) // let button know the parameter order
                            
                            // assign touch handler to the entire row, as the little touch icon is pretty small
                            // Note: need both handlers
                            pView.tag = i
                            pView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTouchHandler)))

                            
                            var p = self.currFilterDesc?.getPositionParameter(key)?.cgPointValue
                            // if position is not set, default to the middle of the image
                            if ((p?.x)! < CGFloat(0.01)) && ((p?.y)! < CGFloat(0.01)) { // approximately (0, 0)
                                let size = InputSource.getSize()
                                p?.x = min (size.width, size.height) / 2
                                p?.y = max (size.width, size.height) / 2
                                self.currFilterDesc?.setPositionParameter(key, position: CIVector(cgPoint: p!))
                                log.debug("Setting default position to centre of image")
                            }
                            log.verbose("...\(pConfig.title) position: \(p!)")
                            
                            pKey.append(key)
                            pView.addSubview(touchButton)
                            textView.frame.size.height = pView.frame.size.height
                            label.frame.size.height = textView.frame.size.height
                            textView.anchorToEdge(.left, padding: 2, width: label.frame.size.width, height: pView.frame.size.height) // re-align
                            touchButton.anchorInCenter(width: pView.frame.size.height, height: pView.frame.size.height)
                            //pView.groupAndFill(group: .horizontal, views: [label, touchButton], padding: 8.0)

                            
                        default:
                            log.error("Invalid parameter type: \(pConfig.type)")
                        }
                        
                        pView.isUserInteractionEnabled = true
                        sliders.append(pView)
                        parameterView.addSubview(pView)
                        numVisibleParams = numVisibleParams + 1
                        i = i + 1
                    }
                }
            }
        }
        
        if numVisibleParams > 0 {
            scrollView?.addSubview(parameterView)
            self.addSubview(scrollView!)
        }
        
    }
    
    
    
    // Attaches an action handler based on the slider index
    fileprivate func attachSliderAction(_ slider:UISlider){

        slider.addTarget(self, action: #selector(self.sliderValueDidChange), for: .valueChanged)
        
        // shared callback for when user ends changing any slider (intended as an update trigger, don't need the value)
        slider.addTarget(self, action: #selector(self.slidersDidEndChange), for: .touchUpInside)
        
        slider.isContinuous = true
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
            let h:CGFloat =  (CGFloat(sliderHeight) * n*1.3).rounded() + 16 // empirical
            parameterView.frame.size.width = titleView.frame.size.width
            parameterView.frame.size.height = h
            scrollView?.contentSize = parameterView.frame.size
            scrollView?.frame.size.height = min(h, CGFloat(4*sliderHeight))
            height = height + parameterView.frame.size.height
            scrollView?.isHidden = false
            //self.backgroundColor = viewBackgroundColor
       } else {
            parameterView.frame.size.width = titleView.frame.size.width
            parameterView.frame.size.height = 0
            scrollView?.frame.size.height = 0
            scrollView?.contentSize = CGSize.zero
            scrollView?.isHidden = true
            //self.backgroundColor = UIColor.clear
        }

        self.frame.size.height = height
        //self.anchorToEdge(.bottom, padding: 1, width: self.frame.size.width, height: self.frame.size.height)


        // layout sub-views
        
        // Place the tile at the top, buttons at the bottom and sliders distributed in between
        titleView.anchorAndFillEdge(.top, xPad: 2.0, yPad: 2.0, otherSize: titleView.frame.size.height)

        if ((currFilterDesc?.getNumDisplayableParameters())! > 0){
            parameterView.groupAndFill(group: .vertical, views: sliders, padding: 2.0)
            scrollView?.alignAndFill(align: .underCentered, relativeTo: titleView, padding: 0, offset: 0)
        }
        
        logSizes()
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
    
    func logSizes(_ f:String = #function, _ l:Int = #line){
        /***/
        log.debug("\(f):\(l)\n " +
            "\(titleLabel.text)\n" +
            "params: \(numVisibleParams)\n" +
            "Title: [\(titleView.frame)], hid:\(titleView.isHidden)\n" +
            "Params:[\(parameterView.frame)], hid:\(parameterView.isHidden)\n" +
            "Scroll:[\(scrollView?.contentSize)], hid:\((scrollView?.isHidden)!)\n" +
            "All:   [\(self.frame)], hid:\(self.isHidden)" )
        /***/
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
        
        if delegate == nil { log.warning("No delegate") }

        // value is set as sliders are moved, so no need to do anything except clean up and return
        delegate?.commitChanges(key: (currFilterDesc?.key)!)
        //dismiss()

    }
    
    @objc func defaultDidPress(){
        if delegate == nil { log.warning("No delegate") }

        currFilterDesc?.reset()
        layoutUI()
   }
    
    @objc func cancelDidPress(){
        if delegate == nil { log.warning("No delegate") }

        // restore saved parameters
        currFilterDesc?.restoreParameters()
        delegate?.cancelChanges(key:  (currFilterDesc?.key)!)
        //dismiss()
    }

    @objc func screenModeDidPress(){
        if delegate == nil { log.warning("No delegate") }

        if fullScreenEnabled {
            screenModeButton?.setImageAsset("ic_full_screen")
            fullScreenEnabled = false
            delegate?.splitScreenrequested()
       } else {
            screenModeButton?.setImageAsset("ic_split_screen")
            fullScreenEnabled = true
            delegate?.fullScreenRequested()
        }
    }
    
    @objc func filterModeDidPress(){
        
        if delegate == nil { log.warning("No delegate") }

        if showFiltersEnabled {
            filterModeButton?.setImageAsset("ic_view")
            showFiltersEnabled = false
            delegate?.showOriginalRequested()
        } else {
            filterModeButton?.setImageAsset("ic_no_view")
            showFiltersEnabled = true
            delegate?.showFiltersRequested()
        }
    }
    
    @objc func sliderValueDidChange(_ sender:UISlider!){
        //log.verbose("change: \(pKey[sender.tag]) = \(sender.value)")
        if !(currFilterDesc?.slow)! { // only update during drag if not a slow filter
            currFilterDesc?.setParameter(pKey[sender.tag], value: sender.value)
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.settingsChanged()
            })
        }
    }
    
    
    @objc func colorSliderValueDidChange(_ sender:GradientSlider!){
        let index = sender.tag
        if !(currFilterDesc?.slow)! { // only update during drag if not a slow filter
            currFilterDesc?.setColorParameter(pKey[index], color: CIColor(color: (gsliders[index]?.getSelectedColor())!))
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.settingsChanged()
            })
        }
}
    
    @objc func slidersDidEndChange(_ sender:UISlider!){
        log.verbose("end: \(pKey[sender.tag]) = \(sender.value)")
        currFilterDesc?.setParameter(pKey[sender.tag], value: sender.value)
        DispatchQueue.main.async(execute: { () -> Void in
            self.delegate?.settingsChanged()
        })
    }
    
    @objc func gslidersDidEndChange(_ sender:GradientSlider!){
        let index = sender.tag
        //log.verbose("Settings changed for color slider \(pKey[index])")
        currFilterDesc?.setColorParameter(pKey[index], color: CIColor(color: (gsliders[index]?.getSelectedColor())!))
        DispatchQueue.main.async(execute: { () -> Void in
            self.delegate?.settingsChanged()
        })
    }
    
  
    // generic touch handler for any view type
    @objc func viewTouchHandler (sender:UITapGestureRecognizer){
        if let view = sender.view {
            let index = view.tag
            log.verbose("Touch pressed for: \(pKey[index])")
            self.requestPosition(key:self.pKey[index])
        } else {
            log.warning("NIL view")
        }
    }

    
    // touch handler for buttons
    @objc func touchDidPress(sender: UIButton!) {
        let index = sender.tag
        log.verbose("Touch pressed for: \(pKey[index])")
        self.requestPosition(key:self.pKey[index])
    }
    
    @objc func requestPosition(key:String) {
        if delegate != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                self.delegate?.positionRequested(key:key)
            })
        } else {
            log.warning("No delegate")
        }
    }


}
