//
//  ToonDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class ToonDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "Toon"
    let title = "Toon"
    
    var show: Bool = true
    var rating: Int = 0

    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration:[ParameterSettings] = [ParameterSettings(title:"threshold", minimumValue:0.0, maximumValue:1.0, initialValue:0.2, isRGB:false),
                                                      ParameterSettings(title:"levels", minimumValue:1.0, maximumValue:32.0, initialValue:8.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:ToonFilter = ToonFilter() // the actual filter
    fileprivate var stash_threshold: Float
    fileprivate var stash_quantizationLevels: Float
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.threshold = parameterConfiguration[0].initialValue
        lclFilter.quantizationLevels = parameterConfiguration[1].initialValue
        stash_threshold = lclFilter.threshold
        stash_quantizationLevels = lclFilter.quantizationLevels
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = ToonFilter()
        restoreParameters()
    }
    
   
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.threshold
        case 2:
            return lclFilter.quantizationLevels
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.threshold = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.quantizationLevels = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.saturation = value1
    //}
    
    func stashParameters() {
        stash_threshold = lclFilter.threshold
        stash_quantizationLevels = lclFilter.quantizationLevels
    }
    
    func restoreParameters(){
        lclFilter.threshold = stash_threshold
        lclFilter.quantizationLevels = stash_quantizationLevels
    }
}
