//
//  BulgeDistortionDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class BulgeDistortionDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "BulgeDistortion"
    let title = "Bulge Distortion"
    let category = FilterCategoryType.visualEffects
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numSliders = 2
    let parameterConfiguration = [ParameterSettings(title:"amount", minimumValue:-1.0, maximumValue:1.0, initialValue:0.5),
                                  ParameterSettings(title:"radius", minimumValue:0.0, maximumValue:1.0, initialValue:0.25)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:BulgeDistortion = BulgeDistortion() // the actual filter
    private var stash_scale: Float
    private var stash_radius: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.scale = parameterConfiguration[0].initialValue
        lclFilter.radius = parameterConfiguration[1].initialValue
        stash_scale = lclFilter.scale
        stash_radius = lclFilter.radius
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.scale
            break
        case 2:
            return lclFilter.radius
            break
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.scale = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.radius = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.scale = value1
    //}
    
    func stashParameters() {
        stash_scale = lclFilter.scale
        stash_radius = lclFilter.radius
    }
    
    func restoreParameters(){
        lclFilter.scale = stash_scale
        lclFilter.radius = stash_radius
    }
}
