//
//  PixellateDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class PixellateDescriptor: FilterDescriptorInterface {
    
    
    let key = "Pixellate"
    let title = "Pixellate"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"fractional width", minimumValue:0.0, maximumValue:0.3, initialValue:0.05, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:Pixellate = Pixellate() // the actual filter
    private var stash_fractionalWidthOfAPixel: Float
    
    
    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.fractionalWidthOfAPixel = parameterConfiguration[0].initialValue
        stash_fractionalWidthOfAPixel = lclFilter.fractionalWidthOfAPixel
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    
    func getParameter(index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.fractionalWidthOfAPixel
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.fractionalWidthOfAPixel = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(index:Int, color:UIColor) {}
    
    
    func stashParameters(){
        stash_fractionalWidthOfAPixel = lclFilter.fractionalWidthOfAPixel
    }
    
    func restoreParameters(){
        lclFilter.fractionalWidthOfAPixel = stash_fractionalWidthOfAPixel
    }
}
