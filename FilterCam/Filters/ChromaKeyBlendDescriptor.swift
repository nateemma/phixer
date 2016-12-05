//
//  ChromaKeyBlendDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class ChromaKeyBlendDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "ChromaKeyBlend"
    let title = "Chroma Key Blend"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"threshold sensitivity", minimumValue:0.0, maximumValue:1.0, initialValue:0.4, isRGB:false),
                                  ParameterSettings(title:"smoothing", minimumValue:0.0, maximumValue:1.0, initialValue:0.1, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.blend
    
    fileprivate var lclFilter:ChromaKeyBlend = ChromaKeyBlend() // the actual filter
    fileprivate var stash_thresholdSensitivity: Float
    fileprivate var stash_smoothing: Float
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.thresholdSensitivity = parameterConfiguration[0].initialValue
        lclFilter.smoothing = parameterConfiguration[1].initialValue
        stash_thresholdSensitivity = lclFilter.thresholdSensitivity
        stash_smoothing = lclFilter.smoothing
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = ChromaKeyBlend()
        restoreParameters()
   }
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.thresholdSensitivity
        case 2:
            return lclFilter.smoothing
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.thresholdSensitivity = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.smoothing = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_thresholdSensitivity = lclFilter.thresholdSensitivity
        stash_smoothing = lclFilter.smoothing
    }
    
    func restoreParameters(){
        lclFilter.thresholdSensitivity = stash_thresholdSensitivity
        lclFilter.smoothing = stash_smoothing
    }
}
