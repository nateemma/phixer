//
//  PinchDistortionDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class PinchDistortionDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "PinchDistortion"
    let title = "Pinch Distortion"
    
    var show: Bool = true
    var rating: Int = 0

    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"amount", minimumValue:-2.0, maximumValue:2.0, initialValue:1.0, isRGB:false),
                                  ParameterSettings(title:"radius", minimumValue:0.0, maximumValue:1.0, initialValue:0.9, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:PinchDistortion = PinchDistortion() // the actual filter
    fileprivate var stash_scale: Float
    fileprivate var stash_radius: Float
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.scale = parameterConfiguration[0].initialValue
        lclFilter.radius = parameterConfiguration[1].initialValue
        stash_scale = lclFilter.scale
        stash_radius = lclFilter.radius
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = PinchDistortion()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.scale
        case 2:
            return lclFilter.radius
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
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
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_scale = lclFilter.scale
        stash_radius = lclFilter.radius
    }
    
    func restoreParameters(){
        lclFilter.scale = stash_scale
        lclFilter.radius = stash_radius
    }
}
