//
//  LuminanceThreshold.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class LuminanceThresholdDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "LuminanceThreshold"
    let title = "Luminance Threshold"
    let category = FilterCategoryType.colorAdjustments
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numSliders = 1
    let parameterConfiguration = [ParameterSettings(title:"threshold", minimumValue:0.0, maximumValue:1.0, initialValue:0.5)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:LuminanceThreshold = LuminanceThreshold() // the actual filter
    private var stash_threshold: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.threshold = parameterConfiguration[0].initialValue
        stash_threshold = lclFilter.threshold
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.threshold
            break
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.threshold = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.threshold = value1
    //}
    
    func stashParameters() {
        stash_threshold = lclFilter.threshold
    }
    
    func restoreParameters(){
        lclFilter.threshold = stash_threshold
    }
}
