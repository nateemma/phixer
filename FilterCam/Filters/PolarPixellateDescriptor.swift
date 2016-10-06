//
//  PolarPixellateFilter.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class PolarPixellateDescriptor: FilterDescriptorInterface {


    let listName = "PolarPixellate"
    let titleName = "PolarPixellate"
    let category = "Effects"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let slider1Configuration = FilterSliderSetting.enabled(title:"pixel size", minimumValue:0.01, maximumValue:0.06, initialValue:0.05)
    let slider2Configuration = FilterSliderSetting.disabled
    let slider3Configuration = FilterSliderSetting.disabled
    let slider4Configuration = FilterSliderSetting.disabled
    
    let filterOperationType = FilterOperationType.singleInput
    
    private var lclFilter:PolarPixellate = PolarPixellate() // the actual filter
    

    init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
    }
    
    
    //MARK: - Required funcs
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    func updateBasedOnSliderValues(slider1Value:Float, slider2Value:Float,  slider3Value:Float,  slider4Value:Float){
        lclFilter.pixelSize = Size(width:slider1Value, height:slider1Value)
    }
}
