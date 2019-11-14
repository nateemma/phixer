//
//  ThemeChooserController.swift
//  phixer
//
//  Created by Philip Price on 11/19/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon


// This is the View Controller for choosing a color scheme

class ThemeChooserController: CoordinatedController {
    
    // Main Views
    var selectionView:UIView! = UIView()
    var controlView:UIView! = UIView()
    var sampleView:UIView! = UIView()
    
    

    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    var selectedThemeKey:String = ""
    var selectedTheme:ThemeParameters? = nil
    var themeList:[String] = []

    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Theme Chooser"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "ThemeChooser"
    }
    
    /////////////////////////////
    // INIT
    /////////////////////////////
    

    /////////////////////////////
    // MARK: - Boilerplate
    /////////////////////////////
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // common setup
        self.prepController()

        displayHeight = view.height
        displayWidth = view.width

        doInit()
        doLayout()
        
        
        self.updateColors()
        
    }
    
    
    
    /////////////////////////////
    // MARK: - Initialisation
    /////////////////////////////
    
    var initDone:Bool = false
    
    
    func doInit(){
        
        if (!initDone){
            initDone = true
            // initialise using currently active theme
            themeList = ThemeManager.getThemeList()
            selectedTheme = ThemeManager.currentTheme()
            selectedThemeKey = selectedTheme!.key
        }
    }
    
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        
        
        //UISettings.showAds = (UISettings.isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //UISettings.showAds = false // debug
        
        
        view.backgroundColor = theme.backgroundColor
        
        
        //top-to-bottom layout scheme
        // Note: need to define and add subviews before modifying constraints
        
        // Selection view
        layoutSelectionView()
        view.addSubview(selectionView)
        
        // Controls view
        layoutControls()
        view.addSubview(controlView)

        // View to show selected colour scheme
        layoutSampleView()
        view.addSubview(sampleView)
        
        // layout constraints

        selectionView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: selectionView.frame.size.height)
        controlView.align(.underCentered, relativeTo: selectionView, padding: 0, width: displayWidth, height: controlView.frame.size.height)
        //sampleView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: sampleView.frame.size.height)
        sampleView.alignAndFillHeight(align: .underCentered, relativeTo: controlView, padding: 0, width: displayWidth-8)

    }
    
    
    
    /////////////////////////////
    // MARK: - Layout Functions
    /////////////////////////////
    
    
    func layoutSelectionView(){
        
        selectionView.frame.size.width = displayWidth
        selectionView.frame.size.height = 2*UISettings.panelHeight

        // Colour Scheme selection
        let themeLabel = UILabel()
        let themeSelector:UIPickerView = UIPickerView()
        
        themeLabel.text = "Color Theme :  "
        themeLabel.textColor = theme.textColor
        themeLabel.textAlignment = .right
        themeSelector.frame.size.width = (displayWidth / 2) - 8
        themeSelector.frame.size.height = UISettings.panelHeight

        themeSelector.delegate = self
        themeSelector.dataSource = self
        
        themeSelector.showsSelectionIndicator = true
        themeSelector.frame.size.width = (displayWidth / 2) - 8
        themeSelector.frame.size.height = UISettings.panelHeight
        themeSelector.setValue(theme.titleTextColor, forKeyPath: "textColor")
        let index = themeList.firstIndex(of: selectedThemeKey)
        themeSelector.selectRow(index!, inComponent: 0, animated: true)

        selectionView.addSubview(themeLabel)
        selectionView.addSubview(themeSelector)
        
        let w:CGFloat = (selectionView.frame.size.width / 2) - 8
        let h:CGFloat = min ((selectionView.frame.size.height / 4), UISettings.panelHeight)
        let pad:CGFloat = 2
        
        // line up the labels on the left
        themeLabel.anchorToEdge(.left, padding: pad, width: w, height: h)

        
        // add the interactive items to the right of their labels
        themeSelector.align(.toTheRightCentered, relativeTo: themeLabel, padding: pad*4, width: themeSelector.frame.size.width, height: themeSelector.frame.size.height)

    }
    
    
    func layoutSampleView(){
        
        // set up the background and border
        sampleView.frame.size.width = displayWidth - 8
        sampleView.frame.size.height = displayHeight - UISettings.topBarHeight - selectionView.frame.size.height - controlView.frame.size.height - 8
        
        selectedTheme = ThemeManager.getTheme(selectedThemeKey)
        sampleView.backgroundColor = selectedTheme!.backgroundColor
        sampleView.layer.borderColor = selectedTheme!.borderColor.cgColor
        sampleView.layer.borderWidth = 4
        
        // clear any existing views
        for view in sampleView.subviews {
            view.removeFromSuperview()
        }
        
        // add items that show modified components. Can't set theme, bacuase that changes the 'real' UI
        
        let numComponents:CGFloat = 5
        let h = min (UISettings.panelHeight, (sampleView.frame.size.height-4)/numComponents).rounded()
        let w = sampleView.frame.size.width - 4
        let rowSize = CGSize(width: w, height: h)
        let itemSize = CGSize(width: w/2, height: h)
        let pad:CGFloat = 4

        // create container views
        let titleView:UIView! = UIView()
        let subtitleView:UIView! = UIView()
        let buttonView:UIView! = UIView()
        let switchView:UIView! = UIView()
        let sliderView:UIView! = UIView()

        for v in [titleView, subtitleView, buttonView, switchView, sliderView] {
            v?.frame.size = itemSize
            v?.backgroundColor = selectedTheme?.backgroundColor
            sampleView.addSubview(v!)
        }

        // Title
        titleView.frame.size = rowSize
        let title = UILabel()
        title.frame.size = rowSize
        title.backgroundColor = selectedTheme?.titleColor
        title.text = "Title"
        title.textAlignment = .center
        title.textColor = selectedTheme?.titleTextColor
        title.font = UIFont.systemFont(ofSize: 24.0, weight: UIFont.Weight.thin)
        titleView.addSubview(title)
        title.fillSuperview(left: pad, right: pad, top: pad, bottom: pad)
        
        // Subtitle
        subtitleView.frame.size = rowSize
        let subtitle = UILabel()
        subtitle.frame.size = rowSize
        subtitle.backgroundColor = selectedTheme?.subtitleColor
        subtitle.text = "Subtitle"
        subtitle.textAlignment = .center
        subtitle.textColor = selectedTheme?.subtitleTextColor
        subtitle.font = UIFont.systemFont(ofSize: 20.0, weight: UIFont.Weight.thin)
        subtitleView.addSubview(subtitle)
        subtitle.fillSuperview(left: pad, right: pad, top: pad, bottom: pad)
        
        // Button
        let buttonLabel = UILabel()
        buttonLabel.frame.size = itemSize
        buttonLabel.backgroundColor = selectedTheme?.backgroundColor
        buttonLabel.text = "Button:    "
        buttonLabel.textAlignment = .right
        buttonLabel.textColor = selectedTheme?.textColor
        buttonLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.thin)
        buttonView.addSubview(buttonLabel)
        
        let button = UIButton()
        button.setTitle("Text", for: .normal)
        button.backgroundColor = selectedTheme?.buttonColor
        button.titleLabel?.textColor = selectedTheme?.textColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.thin)
        button.titleLabel?.textAlignment = .center
        button.frame.size.width = (itemSize.width*0.8).rounded()
        button.frame.size.height = (itemSize.height*0.8).rounded()
        buttonView.addSubview(button)
      
        buttonLabel.anchorToEdge(.left, padding: pad, width: buttonLabel.frame.size.width, height: buttonLabel.frame.size.height)
        button.align(.toTheRightCentered, relativeTo: buttonLabel, padding: pad, width: button.frame.size.width, height: button.frame.size.height)

        // switch
        let switchLabel = UILabel()
        switchLabel.frame.size = itemSize
        switchLabel.backgroundColor = selectedTheme?.backgroundColor
        switchLabel.text = "Switch:    "
        switchLabel.textAlignment = .right
        switchLabel.textColor = selectedTheme?.textColor
        switchLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.thin)
        switchView.addSubview(switchLabel)

        let uiswitch = UISwitch()
        uiswitch.backgroundColor = selectedTheme?.backgroundColor
        uiswitch.onTintColor = selectedTheme?.highlightColor.withAlphaComponent(0.6)
        uiswitch.thumbTintColor = selectedTheme?.borderColor
        uiswitch.tintColor = selectedTheme?.highlightColor
        uiswitch.frame.size.width = (itemSize.height*0.8).rounded()
        uiswitch.frame.size.height = (itemSize.height*0.8).rounded()
        switchView.addSubview(uiswitch)
        
        switchLabel.anchorToEdge(.left, padding: pad, width: switchLabel.frame.size.width, height: switchLabel.frame.size.height)
        uiswitch.align(.toTheRightCentered, relativeTo: switchLabel, padding: pad, width: uiswitch.frame.size.width, height: uiswitch.frame.size.height)

        // slider
        let sliderLabel = UILabel()
        sliderLabel.frame.size = itemSize
        sliderLabel.backgroundColor = selectedTheme?.backgroundColor
        sliderLabel.text = "Slider:    "
        sliderLabel.textAlignment = .right
        sliderLabel.textColor = selectedTheme?.textColor
        sliderLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.thin)
        sliderView.addSubview(sliderLabel)

        let slider = UISlider()
        slider.backgroundColor = selectedTheme?.backgroundColor
        slider.tintColor = selectedTheme?.highlightColor
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = 0.5

        sliderView.addSubview(slider)

        sliderLabel.anchorToEdge(.left, padding: pad, width: sliderLabel.frame.size.width, height: sliderLabel.frame.size.height)
        slider.align(.toTheRightCentered, relativeTo: sliderLabel, padding: pad, width: slider.frame.size.width, height: slider.frame.size.height)
        
        sampleView.groupAndFill(group: .vertical, views: [titleView, subtitleView, buttonView, switchView, sliderView], padding: 2.0)

    }

    
    func layoutControls(){
        controlView.frame.size.width = displayWidth
        controlView.frame.size.height = UISettings.panelHeight
        
        // build a view with a "Done" Button and a "Cancel" button
        let cancelButton:BorderedButton = BorderedButton()
        cancelButton.frame.size.width = displayWidth / 3.0
        cancelButton.frame.size.height = UISettings.panelHeight - 16
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.useGradient = true
        cancelButton.backgroundColor = theme.buttonColor
        controlView.addSubview(cancelButton)
        
        let doneButton:BorderedButton = BorderedButton()
        doneButton.frame.size = cancelButton.frame.size
        doneButton.setTitle("Apply", for: .normal)
        doneButton.useGradient = true
        doneButton.backgroundColor = theme.buttonColor
        controlView.addSubview(doneButton)
        
        // distribute across the control view
        controlView.groupInCenter(group: .horizontal, views: [doneButton, cancelButton], padding: 16, width: doneButton.frame.size.width, height: doneButton.frame.size.height)
        
        // add touch handlers
        doneButton.addTarget(self, action: #selector(self.doneDidPress), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)
        
    }
    
    private func updateColors(){
        DispatchQueue.main.async(execute: {
            self.layoutSampleView()
        })
    }

    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////

    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        // NOTE: in this case, back is the same as cancel
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion:  { [weak self] in
                log.verbose("Leaving...")
            })
            return
        }
    }
    
    @objc func cancelDidPress(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion: { [weak self] in
                log.verbose("Cancelling...")
            })
            return
        }
    }
    
    @objc func doneDidPress(){
        if !selectedThemeKey.isEmpty {
            ThemeManager.applyTheme(key: selectedThemeKey)
            log.debug("Sending themeUpdatedNotification")
            self.coordinator?.themeUpdatedNotification()
        }
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion:  { [weak self] in
                log.verbose("Saving theme \(self?.selectedThemeKey)...")
            })
            return
        }
    }

    
}



/////////////////////////////
// MARK: - Extensions
/////////////////////////////


// UIPicker stuff

extension ThemeChooserController: UIPickerViewDelegate {
    // Number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //log.verbose("[\(row)]: \(colorSchemeList[row])")
        return themeList[row]
    }
    
    // called to set up an item in the list
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin)
            pickerLabel?.textAlignment = .center
        }
        if (row>=0) && (row<self.themeList.count){
            let key = self.themeList[row]
            pickerLabel?.text = ThemeManager.getTheme(key)?.description
            pickerLabel?.textColor = theme.textColor
            pickerLabel?.textAlignment = .left
        } else {
            log.error("Invalid row index:\(row)")
            pickerLabel?.text = "unknown"
            pickerLabel?.textColor = theme.highlightColor
        }
        
        return pickerLabel!
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        if (row>=0) && (row<themeList.count){
            //log.verbose("Selected [\(row)]: \(themeList[row])")
            selectedThemeKey = themeList[row]
            updateColors()
        } else {
            log.error("Invalid row index:\(row)")
        }
    }
}

extension ThemeChooserController: UIPickerViewDataSource{
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //log.verbose("#items:\(colorSchemeList.count)")
        return themeList.count
    }
    
    
}
