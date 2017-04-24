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
    
    var show: Bool = true
    var rating: Int = 0

    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 3
    let parameterConfiguration = [ParameterSettings(title:"start", minimumValue:0.0, maximumValue:0.75, initialValue:0.5, isRGB:false),
                                  ParameterSettings(title:"end", minimumValue:0.6, maximumValue:0.9, initialValue:0.75, isRGB:false),
                                  ParameterSettings(title:"color", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:true)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:Vignette = Vignette() // the actual filter
    fileprivate var stash_start: Float
    fileprivate var stash_end: Float
    fileprivate var stash_color: Color
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.start = parameterConfiguration[0].initialValue
        lclFilter.end = parameterConfiguration[1].initialValue
        lclFilter.color = Color.black
        stash_start = lclFilter.start
        stash_end = lclFilter.end
        stash_color = lclFilter.color
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = Vignette()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.start
        case 2:
            return lclFilter.end
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
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
    
    
    
    
    func setColorParameter(_ index: Int, color:UIColor){
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let color:Color = Color(red: Float(r), green: Float(g), blue: Float(b), alpha: Float(a))
        
        switch(index){
        case 3:
            log.debug("\(parameterConfiguration[index-1].title): (R:\(r), B:\(b), G:\(g))")
            lclFilter.color = color
            break
        default:
            log.error("Invalid index: \(index)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor{
        switch(index){
        case 3:
            return UIColor(red: CGFloat(lclFilter.color.redComponent),
                           green: CGFloat(lclFilter.color.greenComponent),
                           blue: CGFloat(lclFilter.color.blueComponent),
                           alpha: CGFloat(lclFilter.color.alphaComponent))
        default:
            log.error("Invalid index: \(index)")
            return UIColor.black
        }
    }
    
    
    func stashParameters() {
        stash_start = lclFilter.start
        stash_end = lclFilter.end
        stash_color = lclFilter.color
    }
    
    func restoreParameters(){
        lclFilter.start = stash_start
        lclFilter.end = stash_end
        lclFilter.color = stash_color
    }
}
