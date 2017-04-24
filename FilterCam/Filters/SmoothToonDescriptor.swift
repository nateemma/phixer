//
//  SmoothToonDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class SmoothToonDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "SmoothToon"
    let title = "SmoothToon"
    
    var show: Bool = true
    var rating: Int = 0
 
    let filter: BasicOperation?  = nil
    var filterGroup: OperationGroup? = nil
    
    let numParameters = 3
    let parameterConfiguration:[ParameterSettings] = [ParameterSettings(title:"blur radius", minimumValue:0.0, maximumValue:10.0, initialValue:2.0, isRGB:false),
                                                      ParameterSettings(title:"threshold", minimumValue:0.0, maximumValue:1.0, initialValue:0.2, isRGB:false),
                                                      ParameterSettings(title:"levels", minimumValue:1.0, maximumValue:32.0, initialValue:8.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:SmoothToonFilter = SmoothToonFilter() // the actual filter
    fileprivate var stash_blurRadiusInPixels: Float
    fileprivate var stash_threshold: Float
    fileprivate var stash_quantizationLevels: Float
    
    
    required init(){
        filterGroup = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.blurRadiusInPixels = parameterConfiguration[0].initialValue
        lclFilter.threshold = parameterConfiguration[1].initialValue
        lclFilter.quantizationLevels = parameterConfiguration[2].initialValue
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
        stash_threshold = lclFilter.threshold
        stash_quantizationLevels = lclFilter.quantizationLevels
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = SmoothToonFilter()
        restoreParameters()
    }
    
   
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.blurRadiusInPixels
        case 2:
            return lclFilter.threshold
        case 3:
            return lclFilter.quantizationLevels
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.blurRadiusInPixels = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.threshold = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        case 3:
            lclFilter.quantizationLevels = value
            log.debug("\(parameterConfiguration[2].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
        stash_threshold = lclFilter.threshold
        stash_quantizationLevels = lclFilter.quantizationLevels
    }
    
    func restoreParameters(){
        lclFilter.blurRadiusInPixels = stash_blurRadiusInPixels
        lclFilter.threshold = stash_threshold
        lclFilter.quantizationLevels = stash_quantizationLevels
    }
}
