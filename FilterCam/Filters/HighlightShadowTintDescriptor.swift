//
//  HighlightAndShadowTintDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class HighlightAndShadowTintDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "HighlightAndShadowTint"
    let title = "Highlight And Shadow Tint"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 4
    let parameterConfiguration = [ParameterSettings(title:"shadow tint color", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:true),
                                  ParameterSettings(title:"highlight tint color", minimumValue:0.0, maximumValue:1.0, initialValue:0.25, isRGB:true),
                                  ParameterSettings(title:"shadow tint intensity", minimumValue:0.0, maximumValue:1.0, initialValue:0.1, isRGB:false),
                                  ParameterSettings(title:"highlight tint intensity", minimumValue:0.0, maximumValue:1.0, initialValue:0.1, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:HighlightAndShadowTint = HighlightAndShadowTint() // the actual filter
    
    fileprivate var stash_shadowTintColor: Color
    fileprivate var stash_highlightTintColor: Color
    fileprivate var stash_shadowTintIntensity: Float
    fileprivate var stash_highlightTintIntensity: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.shadowTintColor = Color.red
        lclFilter.highlightTintColor = Color.blue
        lclFilter.shadowTintIntensity = parameterConfiguration[2].initialValue
        lclFilter.highlightTintIntensity = parameterConfiguration[3].initialValue
        stash_shadowTintColor = lclFilter.shadowTintColor
        stash_highlightTintColor = lclFilter.highlightTintColor
        stash_shadowTintIntensity = lclFilter.shadowTintIntensity
        stash_highlightTintIntensity = lclFilter.highlightTintIntensity
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 3:
            return lclFilter.shadowTintIntensity
        case 4:
            return lclFilter.highlightTintIntensity
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 3:
            lclFilter.shadowTintIntensity = value
            log.debug("\(parameterConfiguration[2].title):\(value)")
            break
        case 4:
            lclFilter.highlightTintIntensity = value
            log.debug("\(parameterConfiguration[3].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    
    // This filter uses Color parameters, so add those here
    
    
    func setColorParameter(_ index: Int, color:UIColor){
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let color:Color = Color(red: Float(r), green: Float(g), blue: Float(b), alpha: Float(a))
        
        switch(index){
        case 1:
            //log.debug("\(parameterConfiguration[0].title): Color:\(color)")
            log.debug("\(parameterConfiguration[0].title): (R:\(r), B:\(b), G:\(g))")
            lclFilter.shadowTintColor = color
            break
        case 2:
            //log.debug("\(parameterConfiguration[1].title): Color:\(color)")
            log.debug("\(parameterConfiguration[1].title): (R:\(r), B:\(b), G:\(g))")
            lclFilter.highlightTintColor = color
            break
        default:
            log.error("Invalid index: \(index)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor{
        switch(index){
        case 1:
            return UIColor(red: CGFloat(lclFilter.shadowTintColor.redComponent),
                           green: CGFloat(lclFilter.shadowTintColor.greenComponent),
                           blue: CGFloat(lclFilter.shadowTintColor.blueComponent),
                           alpha: CGFloat(lclFilter.shadowTintColor.alphaComponent))
        case 2:
            return UIColor(red: CGFloat(lclFilter.highlightTintColor.redComponent),
                           green: CGFloat(lclFilter.highlightTintColor.greenComponent),
                           blue: CGFloat(lclFilter.highlightTintColor.blueComponent),
                           alpha: CGFloat(lclFilter.highlightTintColor.alphaComponent))
        default:
            log.error("Invalid index: \(index)")
            return UIColor.blue
        }
    }
    
    
    func stashParameters() {
        stash_shadowTintColor = lclFilter.shadowTintColor
        stash_highlightTintColor = lclFilter.highlightTintColor
        stash_shadowTintIntensity = lclFilter.shadowTintIntensity
        stash_highlightTintIntensity = lclFilter.highlightTintIntensity
    }
    
    func restoreParameters(){
        lclFilter.shadowTintColor = stash_shadowTintColor
        lclFilter.highlightTintColor = stash_highlightTintColor
        lclFilter.shadowTintIntensity = stash_shadowTintIntensity
        lclFilter.highlightTintIntensity = stash_highlightTintIntensity
    }
}
