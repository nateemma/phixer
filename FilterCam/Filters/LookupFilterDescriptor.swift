//
//  LookupFilterDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage

// This filter is a little different because it can have multiple instantiations with different lookup files
// note that some parameters have been changed to vars (key, title)

class LookupFilterDescriptor: FilterDescriptorInterface {
    
    
    open var lookupName: String = "lookup.png" {
        didSet {
            lookupInput = PictureInput(imageName:lookupName)
            lclFilter.lookupImage = lookupInput }
    }
    
    fileprivate var lookupInput:PictureInput? = nil

    
    var key = "LookupFilter"
    var title = "LookupFilter"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"intensity", minimumValue:0.0, maximumValue:1.0, initialValue:0.99, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:LookupFilter = LookupFilter() // the actual filter
    fileprivate var stash_intensity: Float
    
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.intensity = parameterConfiguration[0].initialValue
        stash_intensity = lclFilter.intensity
        log.verbose("config: \(parameterConfiguration)")
    }
    
    // func to set the lookup file. Default is lookup.png which does nothing
    
    func setLookupFile(name: String){
        lookupName = name
        lookupInput = PictureInput(imageName:lookupName)
        lclFilter.lookupImage = lookupInput

    }
  
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = LookupFilter()
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
    
    
    func stashParameters() {
        stash_intensity = lclFilter.intensity
    }
    
    func restoreParameters(){
        lclFilter.intensity = stash_intensity
    }
}
