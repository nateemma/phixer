//
//  NobleCornerDetectorDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class NobleCornerDetectorDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "NobleCornerDetector"
    let title = "Noble Corner Detector"
    
    let filter: BasicOperation?  = nil
    var filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"blurRadiusInPixels", minimumValue:0.0, maximumValue:24.0, initialValue:2.0, isRGB:false),
                                  ParameterSettings(title:"sensitivity", minimumValue:0.0, maximumValue:10.0, initialValue:5.0, isRGB:false),
                                  ParameterSettings(title:"threshold", minimumValue:0.0, maximumValue:1.0, initialValue:0.2, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:NobleCornerDetector = NobleCornerDetector() // the actual filter
    private var stash_blurRadiusInPixels: Float
    private var stash_sensitivity: Float
    private var stash_threshold: Float
    
    
    init(){
        filterGroup = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.blurRadiusInPixels = parameterConfiguration[0].initialValue
        lclFilter.sensitivity = parameterConfiguration[1].initialValue
        lclFilter.threshold = parameterConfiguration[2].initialValue
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
        stash_sensitivity = lclFilter.sensitivity
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
            return lclFilter.blurRadiusInPixels
        case 2:
            return lclFilter.sensitivity
        case 3:
            return lclFilter.threshold
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.blurRadiusInPixels = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.sensitivity = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        case 3:
            lclFilter.threshold = value
            log.debug("\(parameterConfiguration[2].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
        stash_sensitivity = lclFilter.sensitivity
        stash_threshold = lclFilter.threshold
    }
    
    func restoreParameters(){
        lclFilter.blurRadiusInPixels = stash_blurRadiusInPixels
        lclFilter.sensitivity = stash_sensitivity
        lclFilter.threshold = stash_threshold
    }
}
