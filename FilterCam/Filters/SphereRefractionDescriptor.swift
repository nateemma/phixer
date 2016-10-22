//
//  GlassSphereRefractionDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class GlassSphereRefractionDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "GlassSphereRefraction"
    let title = "Glass Sphere Refraction"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"radius", minimumValue:0.0, maximumValue:1.0, initialValue:0.15, isRGB:false),
                                  ParameterSettings(title:"refraction", minimumValue:0.0, maximumValue:1.0, initialValue:0.71, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:GlassSphereRefraction = GlassSphereRefraction() // the actual filter
    fileprivate var stash_radius: Float
    fileprivate var stash_refractiveIndex: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.radius = parameterConfiguration[0].initialValue
        lclFilter.refractiveIndex = parameterConfiguration[1].initialValue
        stash_radius = lclFilter.radius
        stash_refractiveIndex = lclFilter.refractiveIndex
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.radius
        case 2:
            return lclFilter.refractiveIndex
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.radius = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.refractiveIndex = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.radius = value1
    //}
    
    func stashParameters() {
        stash_radius = lclFilter.radius
        stash_refractiveIndex = lclFilter.refractiveIndex
    }
    
    func restoreParameters(){
        lclFilter.radius = stash_radius
        lclFilter.refractiveIndex = stash_refractiveIndex
    }
}
