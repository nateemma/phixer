//
//  ThresholdSketchDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class ThresholdSketchDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "ThresholdSketch"
    let title = "Threshold Sketch"
    let category = FilterCategoryType.colorAdjustments
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numSliders = 2
    let parameterConfiguration = [ParameterSettings(title:"threshold", minimumValue:0.0, maximumValue:1.0, initialValue:0.25),
                                  ParameterSettings(title:"edge strength", minimumValue:0.0, maximumValue:4.0, initialValue:1.0)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:ThresholdSketchFilter = ThresholdSketchFilter() // the actual filter
    private var stash_threshold: Float
    private var stash_edgeStrength: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.threshold = parameterConfiguration[0].initialValue
        lclFilter.edgeStrength = parameterConfiguration[1].initialValue
        stash_threshold = lclFilter.threshold
        stash_edgeStrength = lclFilter.edgeStrength
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
        case 2:
            return lclFilter.edgeStrength
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
        case 2:
            lclFilter.edgeStrength = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
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
        stash_edgeStrength = lclFilter.edgeStrength
    }
    
    func restoreParameters(){
        lclFilter.threshold = stash_threshold
        lclFilter.edgeStrength = stash_edgeStrength
    }
}
