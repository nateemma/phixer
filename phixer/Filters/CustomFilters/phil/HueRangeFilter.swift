//
//  HueRangeFilter.swift
//  phixer
//
//  Created by Philip Price on 2/10/19
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter that returns an image with only the hues within the specified range present. All other pixels will be black with zero alpha, i.e. basis for an overlay
class HueRangeFilter: CIFilter {
    
    var inputImage: CIImage?
    private static let defaultColor = CIColor(red: 1.0, green: 206/255, blue: 180/255, alpha: 1.0)
    var inputColor:CIColor = HueRangeFilter.defaultColor
    var inputVariance:CGFloat = 0.1

    // this kernel just looks for colors close to the supplied color (hue). It is more lax on saturation and brightness than hue
    let kernel = CIColorKernel(source:
        "vec3 rgb2hsv(vec3 c) {\n" +
            "    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);\n" +
            "    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));\n" +
            "    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));\n" +
            "    float d = q.x - min(q.w, q.y);\n" +
            "    float e = 1.0e-10;\n" +
            "    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);\n" +
            "}\n" +
            "\n" +
            "kernel vec4 hueRangeFilter(__sample image, __color color, float variance) {\n" +
            "vec3 ihsv = rgb2hsv(image.rgb);\n" +
            "vec3 chsv = rgb2hsv(color.rgb);\n" +
            "float ihue = ihsv.x;\n" +
            "float chue = chsv.x;\n" +
            "vec4 result = vec4(0.0);\n" +
            "//vec4 result = ((ihue>=(chue-variance)) && (ihue<=(chue+variance))) ? image : vec4(0.0);\n" +
            "//if (variance>distance(ihsv, chsv) && (abs(ihue-chue)<(variance/2.0))) {\n" +
            "if (variance>distance(ihsv, chsv) && (abs(ihue-chue)<(0.1))) {\n" +
            "    result = image;\n" +
            "}\n" +
            "return result;\n" +
        "}"
    )

    // default settings
    override func setDefaults() {
        inputImage = nil
        inputColor = HueRangeFilter.defaultColor
        inputVariance = 0.1
    }
    
    
    // filter display name
    func displayName() -> String {
        return "Hue Range"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputColor": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIColor",
                           kCIAttributeDefault: CIColor(red: 1.0, green: 206/255, blue: 180/255, alpha: 1.0),
                           kCIAttributeDisplayName: "Base Color",
                           kCIAttributeMin: 0,
                           kCIAttributeSliderMin: 0,
                           kCIAttributeSliderMax: 0,
                           kCIAttributeType: kCIAttributeTypeColor],
            
            "inputVariance": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.1,
                           kCIAttributeDisplayName: "Variance",
                           kCIAttributeMin: 0,
                           kCIAttributeSliderMin: 0.001,
                           kCIAttributeSliderMax: 0.99,
                           kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
 
    override func value(forKey key: String) -> Any? {
        switch key {
        case "inputImage":
            return inputImage
        case "outputImage":
            return outputImage
        case "inputColor":
            return inputColor
        case "inputVariance":
            return inputVariance
        default:
            log.error("Invalid key: \(key)")
            return nil
        }
    }

    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputColor":
            inputColor = value as! CIColor
        case "inputVariance":
            inputVariance = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage, let kernel = kernel else {
            log.error("No input image")
            return nil
        }
        
        //TODO: allow setting of thresholds, or use average luminance of the input image
        
        let extent = inputImage.extent
        let arguments = [inputImage, inputColor, inputVariance] as [Any]
        
        return kernel.apply(extent: extent, arguments: arguments)
    }
}
