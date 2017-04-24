//
//  CannyEdgeDetectionDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class CannyEdgeDetectionDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "CannyEdgeDetection"
    let title = "Canny Edge Detection"
    
    var show: Bool = true
    var rating: Int = 0
  
    let filter: BasicOperation?  = nil
    var filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"blurRadiusInPixels", minimumValue:0.0, maximumValue:24.0, initialValue:2.0, isRGB:false),
                                  ParameterSettings(title:"upperThreshold", minimumValue:0.0, maximumValue:1.0, initialValue:0.4, isRGB:false),
                                  ParameterSettings(title:"lowerThreshold", minimumValue:0.0, maximumValue:1.0, initialValue:0.1, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:CannyEdgeDetection = CannyEdgeDetection() // the actual filter
    fileprivate var stash_blurRadiusInPixels: Float
    fileprivate var stash_upperThreshold: Float
    fileprivate var stash_lowerThreshold: Float
    
    
    required init(){
        filterGroup = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.blurRadiusInPixels = parameterConfiguration[0].initialValue
        lclFilter.upperThreshold = parameterConfiguration[1].initialValue
        lclFilter.lowerThreshold = parameterConfiguration[2].initialValue
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
        stash_upperThreshold = lclFilter.upperThreshold
        stash_lowerThreshold = lclFilter.lowerThreshold
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = CannyEdgeDetection()
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
            return lclFilter.upperThreshold
        case 3:
            return lclFilter.lowerThreshold
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
            lclFilter.upperThreshold = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        case 3:
            lclFilter.lowerThreshold = value
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
        stash_upperThreshold = lclFilter.upperThreshold
        stash_lowerThreshold = lclFilter.lowerThreshold
    }
    
    func restoreParameters(){
        lclFilter.blurRadiusInPixels = stash_blurRadiusInPixels
        lclFilter.upperThreshold = stash_upperThreshold
        lclFilter.lowerThreshold = stash_lowerThreshold
    }
}
