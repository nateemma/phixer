//
//  EditHSVToolController.swift
//  phixer
//
//  Created by Philip Price on 01/27/19
//  Copyright © 2018 Nateemma. All rights reserved.
//

import UIKit
import Neon
import CoreImage



// This View Controller is a Tool Subcontroller that provides the ability to set Hue, Saturation and Value (Lightness) adjustments to
// various colour channels - similar to Photoshop/Lightroom

class EditHSVToolController: EditBaseToolController {
    


    
 
    ////////////////////
    // 'Virtual' funcs, these must be overidden by the subclass
    ////////////////////
    
    override func getTitle() -> String{
        return "Color Adjustment Editor"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "SimpleEditor" // TODO: write custom help file
    }
    
    // this is called by the Controller base class to build the tool-speciifc display
    override func loadToolView(toolview: UIView){
        buildView(toolview)
    }
    
    
    override func filterReset(){
        initFilter()
    }

    ////////////////////
    // Tool-specific code
    ////////////////////


    // container views
    private var colorView:UIView! = UIView()
    private var sliderView:UIView! = UIView()

    // filter-related
    private var hsvFilter:FilterDescriptor? = nil
    
    struct ColorParameters {
        var key: String = "red"
        var vector: CIVector = CIVector(x: 0.0, y: 1.0, z: 1.0)
        var color: UIColor = MultiBandHSV.red
        
        init(key:String, vector:CIVector, color:UIColor){
            self.key = key
            self.vector = vector
            self.color = color
        }
    }

    private let colorList:[String] = ["red", "orange", "yellow", "green", "aqua", "blue", "purple", "magenta"]
    private var colorViewList:[UIView] = []

    private var colorMap: [String:ColorParameters] = [:]
    private var currColorKey:String = "red"
    private var refColor:UIColor = MultiBandHSV.red
    private var currColorIndex:Int = 0
    private var oldColorIndex:Int = 0

    ////////////////////////
    // the main func
    ////////////////////////
    
    private func buildView(_ toolview: UIView){
        
        
        // set up the view sizes
        colorView.frame.size.height = UISettings.menuHeight
        colorView.frame.size.width = toolview.frame.size.width
        //colorView.backgroundColor = UIColor.red // temp
        
        sliderView.frame.size.height = toolview.frame.size.height - colorView.frame.size.height
        sliderView.frame.size.width = toolview.frame.size.width
        //sliderView.backgroundColor = UIColor.blue // temp
        
        // layout
        toolview.addSubview(colorView)
        toolview.addSubview(sliderView)
        
        colorView.anchorToEdge(.top, padding: 0, width: colorView.frame.size.width, height: colorView.frame.size.height)
        sliderView.align(.underCentered, relativeTo: colorView, padding: 0, width: sliderView.frame.size.width, height: sliderView.frame.size.height)

        
        // populate
        initFilter()
        buildColourView()
        buildSliderView()
        
        // adjust height
        self.resetToolHeight(colorView.frame.size.height + sliderView.frame.size.height)
        
        // set initial color
        selectColor(index:0)
        
    }

    ////////////////////////
    // Filter Management
    ////////////////////////
    
    private func initFilter(){
        // allocate filter and initialise values
        hsvFilter = filterManager.getFilterDescriptor(key: "MultiBandHSV")
        
        // init values here because they could change
        colorMap = ["red": ColorParameters(key: "red", vector: CIVector(x: 0.0, y: 1.0, z: 1.0), color:MultiBandHSV.red),
                    "orange": ColorParameters(key: "orange", vector: CIVector(x: 0.0, y: 1.0, z: 1.0), color:MultiBandHSV.orange),
                    "yellow": ColorParameters(key: "yellow", vector: CIVector(x: 0.0, y: 1.0, z: 1.0), color:MultiBandHSV.yellow),
                    "green": ColorParameters(key: "green", vector: CIVector(x: 0.0, y: 1.0, z: 1.0), color:MultiBandHSV.green),
                    "aqua": ColorParameters(key: "aqua", vector: CIVector(x: 0.0, y: 1.0, z: 1.0), color:MultiBandHSV.aqua),
                    "blue": ColorParameters(key: "blue", vector: CIVector(x: 0.0, y: 1.0, z: 1.0), color:MultiBandHSV.blue),
                    "purple": ColorParameters(key: "purple", vector: CIVector(x: 0.0, y: 1.0, z: 1.0), color:MultiBandHSV.purple),
                    "magenta": ColorParameters(key: "magenta", vector: CIVector(x: 0.0, y: 1.0, z: 1.0), color:MultiBandHSV.magenta)
        ]
        
        setFilterParameters()
        EditManager.addPreviewFilter(hsvFilter)
    }
    
    private func setFilterParameters(){
        hsvFilter?.setVectorParameter("inputRedShift", vector: (colorMap["red"]?.vector)!)
        hsvFilter?.setVectorParameter("inputOrangeShift", vector: (colorMap["orange"]?.vector)!)
        hsvFilter?.setVectorParameter("inputYellowShift", vector: (colorMap["yellow"]?.vector)!)
        hsvFilter?.setVectorParameter("inputGreenShift", vector: (colorMap["green"]?.vector)!)
        hsvFilter?.setVectorParameter("inputAquaShift", vector: (colorMap["aqua"]?.vector)!)
        hsvFilter?.setVectorParameter("inputBlueShift", vector: (colorMap["blue"]?.vector)!)
        hsvFilter?.setVectorParameter("inputPurpleShift", vector: (colorMap["purple"]?.vector)!)
        hsvFilter?.setVectorParameter("inputMagentaShift", vector: (colorMap["magenta"]?.vector)!)
        
        // check that filter is active. If not, re-add it (hack)
        if !EditManager.isPreviewActive() {
            EditManager.addPreviewFilter(hsvFilter)
        }
        
        self.coordinator?.updateRequest(id: self.id)
    }

    ////////////////////////
    // Colour Selection
    ////////////////////////
    
    // builds a display of the colours and their names
    private func buildColourView() {
        colorViewList = []
        var cellWidth = (colorView.frame.size.width  / CGFloat(colorList.count)).rounded()
        let cellHeight = colorView.frame.size.height
        if cellWidth > cellHeight * 0.707 {
            cellWidth = (cellHeight * 0.707).rounded() // 1/sqrt(2)
        }
        
        // build cells for each color
        for i in 0..<colorList.count {
            let color = colorList[i]
            
            // containing view
            let cell = UIView()
            cell.frame.size.width = cellWidth
            cell.frame.size.height = cellHeight
            cell.tag = i
            cell.isUserInteractionEnabled = true
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(colorDidPress)))

            
            // color swatch
            let swatch = UIView()
            swatch.frame.size.width = cellWidth
            swatch.frame.size.height = cellWidth
            swatch.backgroundColor = colorMap[color]?.color
            
            // color label
            let label = UILabel()
            label.text = colorMap[color]?.key
            label.frame.size.width = cellWidth
            label.frame.size.height = cellHeight - cellWidth
            label.textAlignment = .center
            label.textColor = theme.subtitleTextColor
            label.backgroundColor = theme.subtitleColor.withAlphaComponent(0.8)
            label.font = theme.getFont(ofSize: 10.0, weight: UIFont.Weight.thin)
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.numberOfLines = 0
            
            cell.addSubview(swatch)
            cell.addSubview(label)
            swatch.anchorAndFillEdge(.top, xPad: 2, yPad: 2, otherSize: swatch.frame.size.height)
            label.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: label.frame.size.height)

            colorViewList.append(cell)
            colorView.addSubview(cell)
            
       }
        
        colorView.groupInCenter(group: .horizontal, views: colorViewList, padding: 0, width: cellWidth, height: cellHeight)
    }
 
    
    private func selectColor(index:Int){
        if (index >= 0) && (index<colorList.count) {
            let c = colorList[index]
            let p = colorMap[c]
            
            unhighlightCell(currColorIndex)
            highlightCell(index)
            oldColorIndex = currColorIndex
            currColorIndex = index
            currColorKey = c
            refColor = (p?.color)!
            
            setSlidersColor((p?.color)!)
       }
    }
    
    @objc func colorDidPress(_ sender: UITapGestureRecognizer){
        //print("sender:\(sender)")
        let view = sender.view as? UIView
        let index = (view?.tag)!
        if (index >= 0) && (index<colorList.count) {
            selectColor(index:index)
        }
    }
    
    
    private func highlightCell(_ index:Int){
        if (index >= 0) && (index<colorList.count) {
            colorViewList[index].layer.borderWidth = 3.0
            colorViewList[index].layer.borderColor = theme.highlightColor.cgColor
        }
    }

    
    private func unhighlightCell(_ index:Int){
        if (index >= 0) && (index<colorList.count) {
            colorViewList[index].layer.borderWidth = 0.0
            colorViewList[index].layer.borderColor = theme.backgroundColor.cgColor
        }
    }

    ////////////////////////
    // HSB Sliders
    ////////////////////////
    
    
    lazy var sliderHeight: CGFloat = (sliderView.frame.size.height / 4.0).rounded()
    
    // HSB display items
    let hPanel:UIView = UIView()
    let sPanel:UIView = UIView()
    let bPanel:UIView = UIView()
    let hSlider:GradientSlider = GradientSlider()
    let sSlider:GradientSlider = GradientSlider()
    let bSlider:GradientSlider = GradientSlider()
    let hLabel:UILabel = UILabel()
    let sLabel:UILabel = UILabel()
    let bLabel:UILabel = UILabel()
    
    // Colour values
    var hValue:CGFloat = 0.0
    var sValue:CGFloat = 0.0
    var bValue:CGFloat = 0.0
    var aValue:CGFloat = 1.0
    var currColor:UIColor = .black
    var oldColor:UIColor = .black
    
    
    
    // build the view with the HSB/HSV sliders
    private func buildSliderView() {
        
        let sliderWidth:CGFloat = sliderView.frame.size.width * 0.9
        let labelWidth = sliderView.frame.size.width * 0.5
        
        // Gradient Sliders
        for s in [hSlider, sSlider, bSlider] {
            s.frame.size.width = sliderWidth
            s.frame.size.height = UISettings.titleHeight
            //s.hasRainbow = true
            s.minimumValue = 0.0
            s.maximumValue = 1.0
            s.value = 0.5
            s.addTarget(self, action: #selector(self.sliderValueDidChange), for: .valueChanged)
            s.addTarget(self, action: #selector(self.slidersDidEndChange), for: .touchUpInside) // may only need valueChanged ???
        }
        hSlider.tintColor = UIColor.red
        sSlider.tintColor = UIColor.green
        bSlider.tintColor = UIColor.blue
        
        // Labels
        for label in [hLabel, sLabel, bLabel] {
            label.frame.size.width = labelWidth
            label.frame.size.height = UISettings.titleHeight * 0.5
            label.textAlignment = .center
            label.textColor = theme.textColor
            label.font = theme.getFont(ofSize: 12.0, weight: UIFont.Weight.thin)
            sliderView.addSubview(label)
        }
        
        hLabel.text = "Hue"
        sLabel.text = "Saturation"
        bLabel.text = "Brightness"
        
        for v in [hPanel, sPanel, bPanel]{
            v.frame.size.width = sliderView.frame.size.width
            v.frame.size.height = hSlider.frame.size.height + hLabel.frame.size.height
        }
        
        hPanel.addSubview(hLabel)
        hPanel.addSubview(hSlider)
        sliderView.addSubview(hPanel)
        hSlider.anchorToEdge(.bottom, padding: 0, width: hSlider.frame.size.width, height: hSlider.frame.size.height)
        hLabel.align(.aboveCentered, relativeTo: hSlider, padding: 0, width: hLabel.frame.size.width, height: hLabel.frame.size.height)

        sPanel.addSubview(sLabel)
        sPanel.addSubview(sSlider)
        sliderView.addSubview(sPanel)
        sSlider.anchorToEdge(.bottom, padding: 0, width: sSlider.frame.size.width, height: sSlider.frame.size.height)
        sLabel.align(.aboveCentered, relativeTo: sSlider, padding: 0, width: sLabel.frame.size.width, height: sLabel.frame.size.height)

        bPanel.addSubview(bLabel)
        bPanel.addSubview(bSlider)
        sliderView.addSubview(bPanel)
        bSlider.anchorToEdge(.bottom, padding: 0, width: bSlider.frame.size.width, height: bSlider.frame.size.height)
        bLabel.align(.aboveCentered, relativeTo: bSlider, padding: 0, width: bLabel.frame.size.width, height: bLabel.frame.size.height)

        
        // change the height of the container to match the contents
        sliderView.frame.size.height = (3.0 * hPanel.frame.size.height + 8.0)
        
        // line up the sliders in the center
        sliderView.groupAndFill(group: .vertical, views: [hPanel, sPanel, bPanel], padding: 4)
    }

    
    @objc func sliderValueDidChange(_ sender:GradientSlider!){
        updateFromSliders()
        //delegate?.colorChanged(currColor)
    }
    
    
    @objc func slidersDidEndChange(_ sender:GradientSlider!){
        updateFromSliders()
        if !currColor.matches(oldColor){
            oldColor = currColor
            updateFromSliders()
       }
    }

    public func setSlidersColor(_ color:UIColor){
        currColor = color
        color.getHue(&hValue, saturation: &sValue, brightness: &bValue, alpha: &aValue)
        
        hSlider.setValue(hValue, animated: false)
        sSlider.setValue(sValue, animated: false)
        bSlider.setValue(bValue, animated: false)

        updateFromSliders()
        oldColor = currColor // save for later comparison
        
    }
 
    
    // update the sliders, e.g. if the selected colour changes
    private func updateSliders() {
        setSlidersColor((colorMap[currColorKey]?.color)!)
    }

    
    
    // get values from sliders and update associated text
    func updateFromSliders(){
        hValue = CGFloat(hSlider.value)
        sValue = CGFloat(sSlider.value)
        bValue = CGFloat(bSlider.value)
        log.debug("h:\(hValue) s:\(sValue) b:\(bValue)")
        currColor = UIColor(hue: hValue, saturation: sValue, brightness: bValue, alpha: 1.0)

        hSlider.setGradientForHueWithSaturation(sValue, brightness: bValue)
        sSlider.setGradientForSaturationWithHue(hValue, brightness: bValue)
        bSlider.setGradientForBrightnessWithHue(hValue, saturation: sValue)
 
        hSlider.thumbColor = currColor
        sSlider.thumbColor = currColor
        bSlider.thumbColor = currColor

        // the vector expresses the difference from the reference color, not absoulte values. So subtract
        var href:CGFloat=0.0, sref:CGFloat=0.0, bref:CGFloat=0.0, aref:CGFloat=0.0
        refColor.getHue(&href, saturation: &sref, brightness: &bref, alpha: &aref)
        //colorMap[currColorKey]?.vector = CIVector(x: hValue, y: sValue, z: bValue)
        colorMap[currColorKey]?.vector = CIVector(x: hValue-href, y: 1.0+(sValue-sref), z: 1.0+(bValue-bref))
        colorMap[currColorKey]?.color = UIColor(hue: hValue, saturation: sValue, brightness: bValue, alpha: 1.0)

        setFilterParameters()
    }

    
    
} // EditHSVToolController
//########################


//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////



