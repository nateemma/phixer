//
//  EmbossDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class EmbossDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "Emboss"
    let title = "Emboss"
    
    var show: Bool = true
    var rating: Int = 0
   
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"intensity", minimumValue:0.0, maximumValue:4.0, initialValue:1.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:EmbossFilter = EmbossFilter() // the actual filter
    fileprivate var stash_intensity: Float
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.intensity = parameterConfiguration[0].initialValue
        stash_intensity = lclFilter.intensity
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = EmbossFilter()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.intensity
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.intensity = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.intensity = value1
    //}
    
    func stashParameters() {
        stash_intensity = lclFilter.intensity
    }
    
    func restoreParameters(){
        lclFilter.intensity = stash_intensity
    }
}
