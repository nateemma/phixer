//
//  XXXFilter.swift
//  FilterCam
//
//  Created by Philip Price on 10/12/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


public class XXXFilter: BasicOperation {
    public var xxx:Float = 1.0 { didSet { uniformSettings["xxx"] = xxx } }
    
    public init() {
        super.init(fragmentShader:SaturationFragmentShader, numberOfInputs:1)
        
        ({xxx = 1.0})()
    }
}
