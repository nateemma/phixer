//
//  VignetteDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class VignetteDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "Vignette"
    let title = "Vignette"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"start", minimumValue:0.0, maximumValue:0.75, initialValue:0.5, isRGB:false),
                                  ParameterSettings(title:"end", minimumValue:0.6, maximumValue:0.9, initialValue:0.75, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:Vignette = Vignette() // the actual filter
    private var stash_start: Float
    private var stash_end: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.start = parameterConfiguration[0].initialValue
        lclFilter.end = parameterConfiguration[1].initialValue
        stash_start = lclFilter.start
        stash_end = lclFilter.end
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.start
        case 2:
            return lclFilter.end
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.start = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.end = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_start = lclFilter.start
        stash_end = lclFilter.end
    }
    
    func restoreParameters(){
        lclFilter.start = stash_start
        lclFilter.end = stash_end
    }
}
