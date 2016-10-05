//
//  SketchFilter.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class SketchDescriptor: FilterDescriptorInterface {


    let listName = "Sketch"
    let titleName = "Sketch"
    let category = "Effects"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let slider1Configuration = FilterSliderSetting.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.5)
    let slider2Configuration = FilterSliderSetting.disabled
    let slider3Configuration = FilterSliderSetting.disabled
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:SketchFilter = SketchFilter() // the actual filter
    

    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    func updateBasedOnSliderValues(_ slider1Value:CFloat, slider2Value:Float,  slider3Value:Float){
        lclFilter.edgeStrength = slider1Value
    }
}
