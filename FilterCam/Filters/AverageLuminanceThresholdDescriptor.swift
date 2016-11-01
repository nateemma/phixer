//
//  AverageLuminanceThresholdDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class AverageLuminanceThresholdDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "AverageLuminanceThreshold"
    let title = "Average Luminance Threshold"
    
    let filter: BasicOperation?  = nil
    var filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"threshold multiplier", minimumValue:0.0, maximumValue:2.0, initialValue:1.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:AverageLuminanceThreshold = AverageLuminanceThreshold() // the actual filter
    fileprivate var stash_thresholdMultiplier: Float
    
    
    init(){
        filterGroup = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.thresholdMultiplier = parameterConfiguration[0].initialValue
        stash_thresholdMultiplier = lclFilter.thresholdMultiplier
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = AverageLuminanceThreshold()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.thresholdMultiplier
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.thresholdMultiplier = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_thresholdMultiplier = lclFilter.thresholdMultiplier
    }
    
    func restoreParameters(){
        lclFilter.thresholdMultiplier = stash_thresholdMultiplier
    }
}
