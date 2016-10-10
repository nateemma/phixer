//
//  Posterize.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class PosterizeDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "Posterize"
    let title = "Posterize"
    let category = FilterCategoryType.colorAdjustments
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numSliders = 1
    let parameterConfiguration = [ParameterSettings(title:"color levels", minimumValue:1.0, maximumValue:64.0, initialValue:10.0)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:Posterize = Posterize() // the actual filter
    private var stash_colorLevels: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.colorLevels = parameterConfiguration[0].initialValue
        stash_colorLevels = lclFilter.colorLevels
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.colorLevels
            break
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.colorLevels = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.colorLevels = value1
    //}
    
    func stashParameters() {
        stash_colorLevels = lclFilter.colorLevels
    }
    
    func restoreParameters(){
        lclFilter.colorLevels = stash_colorLevels
    }
}
