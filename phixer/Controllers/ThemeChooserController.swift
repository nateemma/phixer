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

class ThemeChooserController: UIViewController {
    
    var theme = ThemeManager.currentTheme()

    
    // Main Views
    var bannerView: TitleView! = TitleView()
    var selectionView:UIView! = UIView()
    var controlView:UIView! = UIView()
    var sampleView:UIView! = UIView()
    
    
    var isLandscape : Bool = false
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let statusBarOffset : CGFloat = 12.0
    
    var selectedThemeKey:String = ""
    var selectedTheme:ThemeParameters? = nil
    var themeList:[String] = []

    
    /////////////////////////////
    // MARK: - Boilerplate
    /////////////////////////////
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load theme here in case it changed
        theme = ThemeManager.currentTheme()
        
        
        doInit()
        doLayout()
        
        
        self.updateColors()
        
    }
    
    
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.current.orientation.isLandscape{
            log.verbose("### Detected change to: Landscape")
            isLandscape = true
        } else {
            log.verbose("### Detected change to: Portrait")
            isLandscape = false
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.removeSubviews()
        self.doLayout()
        self.updateColors()
    }
    
    func removeSubviews(){
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log.warning("Received Memory Warning")
        // Dispose of any resources that can be recreated.
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
        
        
        // NOTE: isLandscape = UIDevice.current.orientation.isLandscape doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        //showAds = (isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //showAds = false // debug
        
        
        view.backgroundColor = theme.backgroundColor
        
        
        //top-to-bottom layout scheme
        // Note: need to define and add subviews before modifying constraints
        
        layoutBanner()
        view.addSubview(bannerView)
        
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
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        selectionView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: selectionView.frame.size.height)
        controlView.align(.underCentered, relativeTo: selectionView, padding: 0, width: displayWidth, height: controlView.frame.size.height)
        //sampleView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: sampleView.frame.size.height)
        sampleView.alignAndFillHeight(align: .underCentered, relativeTo: controlView, padding: 16, width: displayWidth-16)

    }
    
    
    
    /////////////////////////////
    // MARK: - Layout Functions
    /////////////////////////////
    
    
    func layoutBanner(){
        bannerView.frame.size.height = bannerHeight
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = theme.backgroundColor
        bannerView.title = "Color Theme Chooser"
    }
    
    
    func layoutSelectionView(){
        
        selectionView.frame.size.width = displayWidth
        selectionView.frame.size.height = 2*bannerHeight

        // Colour Scheme selection
        let themeLabel = UILabel()
        let themeSelector:UIPickerView = UIPickerView()
        
        themeLabel.text = "Color Theme :  "
        themeLabel.textColor = theme.textColor
        themeLabel.textAlignment = .right
        themeSelector.frame.size.width = (displayWidth / 2) - 8
        themeSelector.frame.size.height = bannerHeight

        themeSelector.delegate = self
        themeSelector.dataSource = self
        
        themeSelector.showsSelectionIndicator = true
        themeSelector.frame.size.width = (displayWidth / 2) - 8
        themeSelector.frame.size.height = bannerHeight
        themeSelector.setValue(theme.titleTextColor, forKeyPath: "textColor")
        let index = themeList.firstIndex(of: selectedThemeKey)
        themeSelector.selectRow(index!, inComponent: 0, animated: true)

        selectionView.addSubview(themeLabel)
        selectionView.addSubview(themeSelector)
        
        let w:CGFloat = (selectionView.frame.size.width / 2) - 8
        let h:CGFloat = min ((selectionView.frame.size.height / 4), bannerHeight)
        let pad:CGFloat = 2
        
        // line up the labels on the left
        themeLabel.anchorToEdge(.left, padding: pad, width: w, height: h)

        
        // add the interactive items to the right of their labels
        themeSelector.align(.toTheRightCentered, relativeTo: themeLabel, padding: pad*4, width: themeSelector.frame.size.width, height: themeSelector.frame.size.height)

    }
    
    
    func layoutSampleView(){
        sampleView.frame.size.width = displayWidth - 16
        sampleView.frame.size.height = 4*bannerHeight
        //TMP:
        selectedTheme = ThemeManager.getTheme(selectedThemeKey)
        sampleView.backgroundColor = selectedTheme!.backgroundColor
        sampleView.layer.borderColor = selectedTheme!.borderColor.cgColor
        sampleView.layer.borderWidth = 2
    }

    
    func layoutControls(){
        controlView.frame.size.width = displayWidth
        controlView.frame.size.height = bannerHeight
        
        // build a view with a "Done" Button and a "Cancel" button
        let cancelButton:BorderedButton = BorderedButton()
        cancelButton.frame.size.width = displayWidth / 3.0
        cancelButton.frame.size.height = bannerHeight - 16
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.useGradient = true
        cancelButton.backgroundColor = theme.buttonColor
        controlView.addSubview(cancelButton)
        
        let doneButton:BorderedButton = BorderedButton()
        doneButton.frame.size = cancelButton.frame.size
        doneButton.setTitle("Done", for: .normal)
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
            dismiss(animated: true, completion:  {
                log.verbose("Leaving...")
            })
            return
        }
    }
    
    @objc func cancelDidPress(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion: {
                log.verbose("Cancelling...")
            })
            return
        }
    }
    
    @objc func doneDidPress(){
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            if !selectedThemeKey.isEmpty {
                ThemeManager.applyTheme(key: selectedThemeKey)
            }
            dismiss(animated: true, completion:  {
                log.verbose("Saving theme \(self.selectedThemeKey)...")
            })
            return
        }
    }

    
}



/////////////////////////////
// MARK: - Extensions
/////////////////////////////


extension ThemeChooserController: TitleViewDelegate {
    func backPressed() {
        backDidPress()
    }
}

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
            pickerLabel?.font = UIFont.systemFont(ofSize: 16.0)
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
            log.verbose("Selected [\(row)]: \(themeList[row])")
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
