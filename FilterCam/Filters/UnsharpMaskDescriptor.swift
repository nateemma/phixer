//
//  UnsharpMaskDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class UnsharpMaskDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "UnsharpMask"
    let title = "Unsharp Mask"
    
    let filter: BasicOperation?  = nil
    var filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"blurRadiusInPixels", minimumValue:0.0, maximumValue:16.0, initialValue:4.0, isRGB:false),
                                  ParameterSettings(title:"intensity", minimumValue:0.0, maximumValue:10.0, initialValue:1.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:UnsharpMask = UnsharpMask() // the actual filter
    fileprivate var stash_blurRadiusInPixels: Float
    fileprivate var stash_intensity: Float
    
    
    init(){
        filterGroup = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.blurRadiusInPixels = parameterConfiguration[0].initialValue
        lclFilter.intensity = parameterConfiguration[1].initialValue
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
        stash_intensity = lclFilter.intensity
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.blurRadiusInPixels
        case 2:
            return lclFilter.intensity
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
            lclFilter.intensity = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters() {
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
        stash_intensity = lclFilter.intensity
    }
    
    func restoreParameters(){
        lclFilter.blurRadiusInPixels = stash_blurRadiusInPixels
        lclFilter.intensity = stash_intensity
    }
}
