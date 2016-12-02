//
//  Clarity.swift
//  FilterCam
//
//  Created by Philip Price on 11/18/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


// Custom Operation that implements a Clarity Adjustment

class Clarity: OperationGroup {
    public var clarity:Float = 1.0 { didSet { opacity.opacity = clarity * 0.1 } }
    
    let unsharpMask = UnsharpMask()
    let blend = LuminosityBlend()
    let opacity = OpacityAdjustment()
    let luminance = Luminance()
    //let luminance = LuminanceThreshold()
    let vibrance = Vibrance()
    
    public override init() {
        super.init()
        
        self.unsharpMask.blurRadiusInPixels = 50.0
        self.unsharpMask.intensity = 2.0
        self.opacity.opacity = 0.1
        self.vibrance.vibrance = 0.05
        
        self.configureGroup{input, output in
            input --> self.vibrance --> self.blend  --> output
                      self.unsharpMask --> self.opacity --> self.blend
            //input --> self.luminance --> self.unsharpMask --> self.opacity --> self.blend --> output
        }
    }
    
}


/***
 
public let UnsharpMaskFragmentShader = "varying highp vec2 textureCoordinate;\n
varying highp vec2 textureCoordinate2;\n
\n
uniform sampler2D inputImageTexture;\n
uniform sampler2D inputImageTexture2; \n \n
uniform highp float intensity;\n \n
void main()\n
    {\n
        lowp vec4 sharpImageColor = texture2D(inputImageTexture, textureCoordinate);\n
        lowp vec3 blurredImageColor = texture2D(inputImageTexture2, textureCoordinate2).rgb;\n
        \n
        gl_FragColor = vec4(sharpImageColor.rgb * intensity + blurredImageColor * (1.0 - intensity), sharpImageColor.a);\n
}\n "

 ***/
