//
//  MonochromeDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/8/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//


import Foundation
import GPUImage


class MonochromeDescriptor: FilterDescriptorInterface {
    
    
    
    let key = "Monochrome"
    let title = "Monochrome"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 2
    let parameterConfiguration = [ParameterSettings(title:"intensity", minimumValue:0.0, maximumValue:1.0, initialValue:1.0, isRGB:false),
                                  ParameterSettings(title:"color", minimumValue:0.0, maximumValue:1.0, initialValue:0.5, isRGB:true)]
    
    // TODO: add "color" parameter as RGBVector4
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:MonochromeFilter = MonochromeFilter() // the actual filter
    
    fileprivate var stash_intensity: Float
    fileprivate var stash_color: Color
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.intensity = parameterConfiguration[0].initialValue
        stash_intensity = lclFilter.intensity
        stash_color = lclFilter.color
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = MonochromeFilter()
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
    
    
    
    // The second parametr is a color parameter
    
    
    func setColorParameter(_ index: Int, color:UIColor){
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        switch(index){
        case 2:
            //log.debug("\(parameterConfiguration[1].title): Color:\(color)")
            log.debug("\(parameterConfiguration[1].title): (R:\(r), B:\(b), G:\(g))")
            lclFilter.color = Color(red: Float(r), green: Float(g), blue: Float(b), alpha: Float(a))
            break
        default:
            log.error("Invalid index: \(index)")
        }
    }
    
    
    func getColorParameter(_ index: Int)->UIColor{
        switch(index){
        case 2:
            return UIColor(red: CGFloat(lclFilter.color.redComponent),
                           green: CGFloat(lclFilter.color.greenComponent),
                           blue: CGFloat(lclFilter.color.blueComponent),
                           alpha: CGFloat(lclFilter.color.alphaComponent))
        default:
            log.error("Invalid index: \(index)")
            return UIColor.blue
        }
    }
    
    
    
    func stashParameters() {
        stash_intensity = lclFilter.intensity
        stash_color = lclFilter.color
    }
    
    func restoreParameters(){
        lclFilter.intensity = stash_intensity
        lclFilter.color = stash_color
    }
}
