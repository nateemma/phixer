//
//  MultiBandHSV.swift
//  MuseCamFilter
//
//  Created by Simon Gladman on 21/03/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import CoreImage
import UIKit

class MultiBandHSV: CIFilter
{
    
    // Colours are public so that you can use them for the UI
    
    //public static let red = CGFloat(0) // UIColor(red: 0.901961, green: 0.270588, blue: 0.270588, alpha: 1).hue()
    public static let red = UIColor(red: 0.901961, green: 0.270588, blue: 0.270588, alpha: 1)
    public static let orange = UIColor(red: 0.901961, green: 0.584314, blue: 0.270588, alpha: 1)
    public static let yellow = UIColor(red: 0.901961, green: 0.901961, blue: 0.270588, alpha: 1)
    public static let green = UIColor(red: 0.270588, green: 0.901961, blue: 0.270588, alpha: 1)
    public static let aqua = UIColor(red: 0.270588, green: 0.901961, blue: 0.901961, alpha: 1)
    public static let blue = UIColor(red: 0.270588, green: 0.270588, blue: 0.901961, alpha: 1)
    public static let purple = UIColor(red: 0.584314, green: 0.270588, blue: 0.901961, alpha: 1)
    public static let magenta = UIColor(red: 0.901961, green: 0.270588, blue: 0.901961, alpha: 1)

    let multiBandHSVKernel: CIColorKernel =
    {
        
        var shaderString = ""
        
        // red is zero because that is our reference point (origin) in the hue scale
        //shaderString += "#define red \(CGFloat(0.0)) \n"
        shaderString += "#define red \(MultiBandHSV.red.hue()) \n"
        shaderString += "#define orange \(MultiBandHSV.orange.hue()) \n"
        shaderString += "#define yellow \(MultiBandHSV.yellow.hue()) \n"
        shaderString += "#define green \(MultiBandHSV.green.hue()) \n"
        shaderString += "#define aqua \(MultiBandHSV.aqua.hue()) \n"
        shaderString += "#define blue \(MultiBandHSV.blue.hue()) \n"
        shaderString += "#define purple \(MultiBandHSV.purple.hue()) \n"
        shaderString += "#define magenta \(MultiBandHSV.magenta.hue()) \n"
        
        shaderString += "vec3 rgb2hsv(vec3 c)"
        shaderString += "{"
        shaderString += "    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);"
        shaderString += "    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));"
        shaderString += "    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));"
        
        shaderString += "    float d = q.x - min(q.w, q.y);"
        shaderString += "    float e = 1.0e-10;"
        shaderString += "    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);"
        shaderString += "}"
        
        shaderString += "vec3 hsv2rgb(vec3 c)"
        shaderString += "{"
        shaderString += "    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);"
        shaderString += "    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);"
        shaderString += "    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);"
        shaderString += "}"
        
        shaderString += "vec3 smoothTreatment(vec3 hsv, float hueEdge0, float hueEdge1, vec3 shiftEdge0, vec3 shiftEdge1)"
        shaderString += "{"
        shaderString += " float smoothedHue = smoothstep(hueEdge0, hueEdge1, hsv.x);"
        shaderString += " float hue = hsv.x + (shiftEdge0.x + ((shiftEdge1.x - shiftEdge0.x) * smoothedHue));"
        shaderString += " float sat = hsv.y * (shiftEdge0.y + ((shiftEdge1.y - shiftEdge0.y) * smoothedHue));"
        shaderString += " float lum = hsv.z * (shiftEdge0.z + ((shiftEdge1.z - shiftEdge0.z) * smoothedHue));"
        shaderString += " return vec3(hue, sat, lum);"
        shaderString += "}"
        
        shaderString += "kernel vec4 kernelFunc(__sample pixel,"
        shaderString += "  vec3 redShift, vec3 orangeShift, vec3 yellowShift, vec3 greenShift,"
        shaderString += "  vec3 aquaShift, vec3 blueShift, vec3 purpleShift, vec3 magentaShift)"
        
        shaderString += "{"
        shaderString += " vec3 hsv = rgb2hsv(pixel.rgb); \n"
        
        shaderString += " if (hsv.x < orange){                          hsv = smoothTreatment(hsv, 0.0, orange, redShift, orangeShift);} \n"
        shaderString += " else if (hsv.x >= orange && hsv.x < yellow){  hsv = smoothTreatment(hsv, orange, yellow, orangeShift, yellowShift); } \n"
        shaderString += " else if (hsv.x >= yellow && hsv.x < green){   hsv = smoothTreatment(hsv, yellow, green, yellowShift, greenShift);  } \n"
        shaderString += " else if (hsv.x >= green && hsv.x < aqua){     hsv = smoothTreatment(hsv, green, aqua, greenShift, aquaShift);} \n"
        shaderString += " else if (hsv.x >= aqua && hsv.x < blue){      hsv = smoothTreatment(hsv, aqua, blue, aquaShift, blueShift);} \n"
        shaderString += " else if (hsv.x >= blue && hsv.x < purple){    hsv = smoothTreatment(hsv, blue, purple, blueShift, purpleShift);} \n"
        shaderString += " else if (hsv.x >= purple && hsv.x < magenta){ hsv = smoothTreatment(hsv, purple, magenta, purpleShift, magentaShift);} \n"
        shaderString += " else {                                        hsv = smoothTreatment(hsv, magenta, 1.0, magentaShift, redShift); }; \n"
        
        shaderString += "return vec4(hsv2rgb(hsv), 1.0);"
        shaderString += "}"

        return CIColorKernel(source: shaderString)!
    }()
    
    var inputImage: CIImage?
    
    var inputRedShift = CIVector(x: 0, y: 1, z: 1)
    var inputOrangeShift = CIVector(x: 0, y: 1, z: 1)
    var inputYellowShift = CIVector(x: 0, y: 1, z: 1)
    var inputGreenShift = CIVector(x: 0, y: 1, z: 1)
    var inputAquaShift = CIVector(x: 0, y: 1, z: 1)
    var inputBlueShift = CIVector(x: 0, y: 1, z: 1)
    var inputPurpleShift = CIVector(x: 0, y: 1, z: 1)
    var inputMagentaShift = CIVector(x: 0, y: 1, z: 1)
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "MultiBandHSV",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRedShift": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Red Shift (HSL)",
                kCIAttributeDescription: "Set the hue, saturation and lightness for this color band.",
                kCIAttributeDefault: CIVector(x: 0, y: 1, z: 1),
                kCIAttributeType: kCIAttributeTypePosition3],
            
            "inputOrangeShift": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Orange Shift (HSL)",
                kCIAttributeDescription: "Set the hue, saturation and lightness for this color band.",
                kCIAttributeDefault: CIVector(x: 0, y: 1, z: 1),
                kCIAttributeType: kCIAttributeTypePosition3],
            
            "inputYellowShift": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Yellow Shift (HSL)",
                kCIAttributeDescription: "Set the hue, saturation and lightness for this color band.",
                kCIAttributeDefault: CIVector(x: 0, y: 1, z: 1),
                kCIAttributeType: kCIAttributeTypePosition3],
            
            "inputGreenShift": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Green Shift (HSL)",
                kCIAttributeDescription: "Set the hue, saturation and lightness for this color band.",
                kCIAttributeDefault: CIVector(x: 0, y: 1, z: 1),
                kCIAttributeType: kCIAttributeTypePosition3],
            
            "inputAquaShift": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Aqua Shift (HSL)",
                kCIAttributeDescription: "Set the hue, saturation and lightness for this color band.",
                kCIAttributeDefault: CIVector(x: 0, y: 1, z: 1),
                kCIAttributeType: kCIAttributeTypePosition3],
            
            "inputBlueShift": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Blue Shift (HSL)",
                kCIAttributeDescription: "Set the hue, saturation and lightness for this color band.",
                kCIAttributeDefault: CIVector(x: 0, y: 1, z: 1),
                kCIAttributeType: kCIAttributeTypePosition3],
            
            "inputPurpleShift": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Purple Shift (HSL)",
                kCIAttributeDescription: "Set the hue, saturation and lightness for this color band.",
                kCIAttributeDefault: CIVector(x: 0, y: 1, z: 1),
                kCIAttributeType: kCIAttributeTypePosition3],
            
            "inputMagentaShift": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIVector",
                kCIAttributeDisplayName: "Magenta Shift (HSL)",
                kCIAttributeDescription: "Set the hue, saturation and lightness for this color band.",
                kCIAttributeDefault: CIVector(x: 0, y: 1, z: 1),
                kCIAttributeType: kCIAttributeTypePosition3],
            ]
    }

    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputRedShift":
            inputRedShift = value as! CIVector
        case "inputOrangeShift":
            inputOrangeShift = value as! CIVector
        case "inputYellowShift":
            inputYellowShift = value as! CIVector
        case "inputGreenShift":
            inputGreenShift = value as! CIVector
        case "inputAquaShift":
            inputAquaShift = value as! CIVector
        case "inputBlueShift":
            inputBlueShift = value as! CIVector
        case "inputPurpleShift":
            inputPurpleShift = value as! CIVector
        case "inputMagentaShift":
            inputMagentaShift = value as! CIVector
        default:
            log.error("Invalid key: \(key)")
        }
    }

    
    // Note: for CIColor or CIVector params (anything not a float or reference), you need to override the get function:
    override func value(forKey key: String) -> Any? {
        switch key {
        case "inputImage":
            return inputImage
        case "inputRedShift":
            return inputRedShift
        case "inputOrangeShift":
            return inputOrangeShift
        case "inputYellowShift":
            return inputYellowShift
        case "inputGreenShift":
            return inputGreenShift
        case "inputAquaShift":
            return inputAquaShift
        case "inputBlueShift":
            return inputBlueShift
        case "inputPurpleShift":
            return inputPurpleShift
        case "inputMagentaShift":
            return inputMagentaShift
        default:
            log.error("Invalid key: \(key)")
            return nil
        }
    }

    
    override var outputImage: CIImage?
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        return multiBandHSVKernel.apply(extent: inputImage.extent,
            arguments: [inputImage,
                inputRedShift,
                inputOrangeShift,
                inputYellowShift,
                inputGreenShift,
                inputAquaShift,
                inputBlueShift,
                inputPurpleShift,
                inputMagentaShift])
    }
}

