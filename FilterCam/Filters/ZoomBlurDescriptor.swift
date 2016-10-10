//
//  ZoomBlur.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class ZoomBlurDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "ZoomBlur"
    let title = "Zoom Blur"
    let category = FilterCategoryType.colorAdjustments
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numSliders = 1
    let parameterConfiguration = [ParameterSettings(title:"blur size", minimumValue:0.0, maximumValue:2.5, initialValue:1.0)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:ZoomBlur = ZoomBlur() // the actual filter
    private var stash_blurSize: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.blurSize = parameterConfiguration[0].initialValue
        stash_blurSize = lclFilter.blurSize
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.blurSize
            break
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.blurSize = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.blurSize = value1
    //}
    
    func stashParameters() {
        stash_blurSize = lclFilter.blurSize
    }
    
    func restoreParameters(){
        lclFilter.blurSize = stash_blurSize
    }
}
