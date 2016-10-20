//
//  ChromaKeyingDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class ChromaKeyingDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "ChromaKeying"
    let title = "ChromaKeying"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 3
    let parameterConfiguration = [ParameterSettings(title:"threshold sensitivity", minimumValue:0.0, maximumValue:1.0, initialValue:0.4, isRGB:false),
                                  ParameterSettings(title:"smoothing", minimumValue:0.0, maximumValue:1.0, initialValue:0.1, isRGB:false),
                                  ParameterSettings(title:"color to replace", minimumValue:0.0, maximumValue:1.0, initialValue:0.1, isRGB:true)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:ChromaKeying = ChromaKeying() // the actual filter
    fileprivate var stash_thresholdSensitivity: Float
    fileprivate var stash_smoothing: Float
    fileprivate var stash_colorToReplace: Color
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.thresholdSensitivity = parameterConfiguration[0].initialValue
        lclFilter.smoothing = parameterConfiguration[1].initialValue
        stash_thresholdSensitivity = lclFilter.thresholdSensitivity
        stash_smoothing = lclFilter.smoothing
        stash_colorToReplace = Color.green
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.thresholdSensitivity
        case 2:
            return lclFilter.smoothing
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.thresholdSensitivity = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.smoothing = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
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
        switch(index){
        case 3:
            log.debug("\(parameterConfiguration[2].title): (R:\(r), B:\(b), G:\(g))")
            lclFilter.colorToReplace = Color(red: Float(r), green: Float(g), blue: Float(b), alpha: Float(a))
            break

        default:
            log.error("Invalid index: \(index)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor{
        switch(index){
        case 3:
            return UIColor(red: CGFloat(lclFilter.colorToReplace.redComponent),
                           green: CGFloat(lclFilter.colorToReplace.greenComponent),
                           blue: CGFloat(lclFilter.colorToReplace.blueComponent),
                           alpha: CGFloat(lclFilter.colorToReplace.alphaComponent))

        default:
            log.error("Invalid index: \(index)")
            return UIColor.blue
        }
    }
    
    
    func stashParameters() {
        stash_thresholdSensitivity = lclFilter.thresholdSensitivity
        stash_smoothing = lclFilter.smoothing
        stash_colorToReplace = lclFilter.colorToReplace
    }
    
    func restoreParameters(){
        lclFilter.thresholdSensitivity = stash_thresholdSensitivity
        lclFilter.smoothing = stash_smoothing
        lclFilter.colorToReplace = stash_colorToReplace
    }
}
