//
//  HighlightsDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class HighlightsDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "Highlights"
    let title = "Highlights and Shadows"
    let category = FilterCategoryType.colorAdjustments
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numSliders = 2
    let parameterConfiguration = [ParameterSettings(title:"highlights", minimumValue:0.0, maximumValue:1.0, initialValue:1.0),
                                  ParameterSettings(title:"shadows", minimumValue:0.0, maximumValue:1.0, initialValue:0.0)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:HighlightsAndShadows = HighlightsAndShadows() // the actual filter
    private var stash_highlights: Float
    private var stash_shadows: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.highlights = parameterConfiguration[0].initialValue
        lclFilter.shadows = parameterConfiguration[1].initialValue
        stash_highlights = lclFilter.highlights
        stash_shadows = lclFilter.shadows
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.highlights
            break
        case 2:
            return lclFilter.shadows
            break
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.highlights = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        case 2:
            lclFilter.shadows = value
            log.debug("\(parameterConfiguration[1].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    //func updateParameters(value1:Float, value2:Float,  value3:Float,  value4:Float){
    //    lclFilter.highlights = value1
    //}
    
    func stashParameters() {
        stash_highlights = lclFilter.highlights
        stash_shadows = lclFilter.shadows
    }
    
    func restoreParameters(){
        lclFilter.highlights = stash_highlights
        lclFilter.shadows = stash_shadows
    }
}
