//
//  RGBChannelCompositing.swift
//  Filterpedia
//
//  Created by Simon Gladman on 20/01/2016.
//  Modified by Phil Price, 06/22/19
//  Copyright © 2016 Simon Gladman. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>

import CoreImage

let tau = CGFloat(Double.pi * 2)

/// `RGBChannelCompositing` filter takes three input images and composites them together
/// by their color channels, the output RGB is `(inputRed.r, inputGreen.g, inputBlue.b)`

class RGBChannelCompositing: CIFilter
{
    var inputRedImage : CIImage?
    var inputGreenImage : CIImage?
    var inputBlueImage : CIImage?
    
    let rgbChannelCompositingKernel = CIColorKernel(source:
        "kernel vec4 rgbChannelCompositing(__sample red, __sample green, __sample blue)" +
        "{" +
        "   return vec4(red.r, green.g, blue.b, 1.0);" +
        "}"
    )
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            // for compatibility only, do nothing
            let x=0
        case "inputRedImage":
            inputRedImage = value as? CIImage
        case "inputGreenImage":
            inputGreenImage = value as? CIImage
        case "inputBlueImage":
            inputBlueImage = value as? CIImage
        default:
            log.error("Invalid key: \(key)")
        }
    }
    

    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "RGB Compositing",
            
            "inputRedImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Red Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputGreenImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Green Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputBlueImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Blue Image",
                kCIAttributeType: kCIAttributeTypeImage]
        ]
    }
    
    override var outputImage: CIImage! {
        guard let inputRedImage = inputRedImage,
            let inputGreenImage = inputGreenImage,
            let inputBlueImage = inputBlueImage,
            let rgbChannelCompositingKernel = rgbChannelCompositingKernel else {
            return nil
        }
        
        let extent = inputRedImage.extent.union(inputGreenImage.extent.union(inputBlueImage.extent))
        let arguments = [inputRedImage, inputGreenImage, inputBlueImage]
        
        return rgbChannelCompositingKernel.apply(extent: extent, arguments: arguments)
    }
}




/// `RGBChannelToneCurve` allows individual tone curves to be applied to each channel.
/// The X (input intensity) and y (output intensity) are supplied the R, G and B channels
/// If not specified, all curves default to linear tone curves
/// ```
class RGBChannelToneCurve: CIFilter {
    var inputImage: CIImage?
    
    var inputRedXvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    var inputGreenXvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    var inputBlueXvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    
    var inputRedYvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    var inputGreenYvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    var inputBlueYvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)

    let rgbChannelCompositing = RGBChannelCompositing()
    
    override func setDefaults() {
        inputRedXvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        inputGreenXvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        inputBlueXvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        
        inputRedYvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        inputGreenYvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
        inputBlueYvalues = CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputRedXvalues":
            inputRedXvalues = value as! CIVector
        case "inputGreenXvalues":
            inputGreenXvalues = value as! CIVector
        case "inputBlueXvalues":
            inputBlueXvalues = value as! CIVector
        case "inputRedYvalues":
            inputRedYvalues = value as! CIVector
        case "inputGreenYvalues":
            inputGreenYvalues = value as! CIVector
        case "inputBlueYvalues":
            inputBlueYvalues = value as! CIVector
        default:
            log.error("Invalid key: \(key)")
        }
    }
    

    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "RGB Tone Curve",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRedXvalues": [kCIAttributeIdentity: 0,
                                kCIAttributeClass: "CIVector",
                                kCIAttributeDefault: CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5),
                                kCIAttributeDisplayName: "Red 'x' values",
                                kCIAttributeDescription: "Red tone curve 'x' values",
                                kCIAttributeType: kCIAttributeTypeOffset],
            
            "inputRedYvalues": [kCIAttributeIdentity: 0,
                                kCIAttributeClass: "CIVector",
                                kCIAttributeDefault: CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5),
                                kCIAttributeDisplayName: "Red 'y' values",
                                kCIAttributeDescription: "Red tone curve 'y' values",
                                kCIAttributeType: kCIAttributeTypeOffset],

            "inputGreenXvalues": [kCIAttributeIdentity: 0,
                                  kCIAttributeClass: "CIVector",
                                  kCIAttributeDefault: CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5),
                                  kCIAttributeDisplayName: "Green 'x' values",
                                  kCIAttributeDescription: "Green tone curve 'x' values",
                                  kCIAttributeType: kCIAttributeTypeOffset],

            "inputGreenYvalues": [kCIAttributeIdentity: 0,
                                  kCIAttributeClass: "CIVector",
                                  kCIAttributeDefault: CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5),
                                  kCIAttributeDisplayName: "Green 'y' values",
                                  kCIAttributeDescription: "Green tone curve 'y' values",
                                  kCIAttributeType: kCIAttributeTypeOffset],

            "inputBlueXvalues": [kCIAttributeIdentity: 0,
                                 kCIAttributeClass: "CIVector",
                                 kCIAttributeDefault: CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5),
                                 kCIAttributeDisplayName: "Blue 'x' values",
                                 kCIAttributeDescription: "Blue tone curve 'x' values",
                                 kCIAttributeType: kCIAttributeTypeOffset],

            "inputBlueYvalues": [kCIAttributeIdentity: 0,
                                 kCIAttributeClass: "CIVector",
                                 kCIAttributeDefault: CIVector(values: [0.0, 0.25, 0.5, 0.75, 1.0], count: 5),
                                 kCIAttributeDisplayName: "Blue 'y' values",
                                 kCIAttributeDescription: "Blue tone curve 'y' values",
                                 kCIAttributeType: kCIAttributeTypeOffset]
        ]
    }
    
    override var outputImage: CIImage! {
        guard let inputImage = inputImage else {
            return nil
        }
        
        let red = inputImage.applyingFilter("CIToneCurve",
                                            parameters: [
                                                "inputPoint0": CIVector(x: inputRedXvalues.value(at: 0), y: inputRedYvalues.value(at: 0)),
                                                "inputPoint1": CIVector(x: inputRedXvalues.value(at: 1), y: inputRedYvalues.value(at: 1)),
                                                "inputPoint2": CIVector(x: inputRedXvalues.value(at: 2), y: inputRedYvalues.value(at: 2)),
                                                "inputPoint3": CIVector(x: inputRedXvalues.value(at: 3), y: inputRedYvalues.value(at: 3)),
                                                "inputPoint4": CIVector(x: inputRedXvalues.value(at: 4), y: inputRedYvalues.value(at: 4))
            ])
        
        let green = inputImage.applyingFilter("CIToneCurve",
                                              parameters: [
                                                "inputPoint0": CIVector(x: inputGreenXvalues.value(at: 0), y: inputGreenYvalues.value(at: 0)),
                                                "inputPoint1": CIVector(x: inputGreenXvalues.value(at: 1), y: inputGreenYvalues.value(at: 1)),
                                                "inputPoint2": CIVector(x: inputGreenXvalues.value(at: 2), y: inputGreenYvalues.value(at: 2)),
                                                "inputPoint3": CIVector(x: inputGreenXvalues.value(at: 3), y: inputGreenYvalues.value(at: 3)),
                                                "inputPoint4": CIVector(x: inputGreenXvalues.value(at: 4), y: inputGreenYvalues.value(at: 4))
            ])
        
        let blue = inputImage.applyingFilter("CIToneCurve",
                                             parameters: [
                                                "inputPoint0": CIVector(x: inputBlueXvalues.value(at: 0), y: inputBlueYvalues.value(at: 0)),
                                                "inputPoint1": CIVector(x: inputBlueXvalues.value(at: 1), y: inputBlueYvalues.value(at: 1)),
                                                "inputPoint2": CIVector(x: inputBlueXvalues.value(at: 2), y: inputBlueYvalues.value(at: 2)),
                                                "inputPoint3": CIVector(x: inputBlueXvalues.value(at: 3), y: inputBlueYvalues.value(at: 3)),
                                                "inputPoint4": CIVector(x: inputBlueXvalues.value(at: 4), y: inputBlueYvalues.value(at: 4))
            ])
        
        rgbChannelCompositing.inputRedImage = red
        rgbChannelCompositing.inputGreenImage = green
        rgbChannelCompositing.inputBlueImage = blue
        
        return rgbChannelCompositing.outputImage
    }
}




/// `RGBChannelBrightnessAndContrast` controls brightness & contrast per color channel

class RGBChannelBrightnessAndContrast: CIFilter {
    var inputImage: CIImage?
    
    var inputRedBrightness: CGFloat = 0
    var inputRedContrast: CGFloat = 1
    
    var inputGreenBrightness: CGFloat = 0
    var inputGreenContrast: CGFloat = 1
    
    var inputBlueBrightness: CGFloat = 0
    var inputBlueContrast: CGFloat = 1
    
    let rgbChannelCompositing = RGBChannelCompositing()
    
    override func setDefaults() {
        inputRedBrightness = 0
        inputRedContrast = 1
        
        inputGreenBrightness = 0
        inputGreenContrast = 1
        
        inputBlueBrightness = 0
        inputBlueContrast = 1
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputRedBrightness":
            inputRedBrightness = value as! CGFloat
        case "inputRedContrast":
            inputRedContrast = value as! CGFloat
        case "inputGreenBrightness":
            inputRedBrightness = value as! CGFloat
        case "inputGreenContrast":
            inputGreenContrast = value as! CGFloat
        case "inputBlueBrightness":
            inputBlueBrightness = value as! CGFloat
        case "inputBlueContrast":
            inputBlueContrast = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }
    

    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "RGB Brightness And Contrast",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRedBrightness": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0,
                kCIAttributeDisplayName: "Red Brightness",
                kCIAttributeMin: 1,
                kCIAttributeSliderMin: -1,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputRedContrast": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1,
                kCIAttributeDisplayName: "Red Contrast",
                kCIAttributeMin: 0.25,
                kCIAttributeSliderMin: 0.25,
                kCIAttributeSliderMax: 4,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputGreenBrightness": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0,
                kCIAttributeDisplayName: "Green Brightness",
                kCIAttributeMin: 1,
                kCIAttributeSliderMin: -1,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputGreenContrast": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1,
                kCIAttributeDisplayName: "Green Contrast",
                kCIAttributeMin: 0.25,
                kCIAttributeSliderMin: 0.25,
                kCIAttributeSliderMax: 4,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputBlueBrightness": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0,
                kCIAttributeDisplayName: "Blue Brightness",
                kCIAttributeMin: 1,
                kCIAttributeSliderMin: -1,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputBlueContrast": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 1,
                kCIAttributeDisplayName: "Blue Contrast",
                kCIAttributeMin: 0.25,
                kCIAttributeSliderMin: 0.25,
                kCIAttributeSliderMax: 4,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    override var outputImage: CIImage! {
        guard let inputImage = inputImage else {
            return nil
        }
        
        let red = inputImage.applyingFilter("CIColorControls",
                                            parameters: [
                kCIInputBrightnessKey: inputRedBrightness,
                kCIInputContrastKey: inputRedContrast])
        
        let green = inputImage.applyingFilter("CIColorControls",
                                              parameters: [
                kCIInputBrightnessKey: inputGreenBrightness,
                kCIInputContrastKey: inputGreenContrast])
        
        let blue = inputImage.applyingFilter("CIColorControls",
                                             parameters: [
                kCIInputBrightnessKey: inputBlueBrightness,
                kCIInputContrastKey: inputBlueContrast])
        
        rgbChannelCompositing.inputRedImage = red
        rgbChannelCompositing.inputGreenImage = green
        rgbChannelCompositing.inputBlueImage = blue
        
        let finalImage = rgbChannelCompositing.outputImage
        
        return finalImage
    }
}

/// `ChromaticAberration` offsets an image's RGB channels around an equilateral triangle

class ChromaticAberration: CIFilter {
    var inputImage: CIImage?
    
    var inputAngle: CGFloat = 0
    var inputRadius: CGFloat = 2
    
    let rgbChannelCompositing = RGBChannelCompositing()
    
    override func setDefaults() {
        inputAngle = 0
        inputRadius = 2
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputAngle":
            inputAngle = value as! CGFloat
        case "inputRadius":
            inputRadius = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }
    
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "Chromatic Abberation",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputAngle": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0,
                kCIAttributeDisplayName: "Angle",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: tau,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 2,
                kCIAttributeDisplayName: "Radius",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 25,
                kCIAttributeType: kCIAttributeTypeScalar],
        ]
    }
    
    override var outputImage: CIImage! {
        guard let inputImage = inputImage else {
            return nil
        }
        
        let redAngle = inputAngle + tau
        let greenAngle = inputAngle + tau * 0.333
        let blueAngle = inputAngle + tau * 0.666
        
        let redTransform = CGAffineTransform(translationX: sin(redAngle) * inputRadius, y: cos(redAngle) * inputRadius)
        let greenTransform = CGAffineTransform(translationX: sin(greenAngle) * inputRadius, y: cos(greenAngle) * inputRadius)
        let blueTransform = CGAffineTransform(translationX: sin(blueAngle) * inputRadius, y: cos(blueAngle) * inputRadius)
        
        let red = inputImage.applyingFilter("CIAffineTransform",
                                            parameters: [kCIInputTransformKey: NSValue(cgAffineTransform: redTransform)])
            .cropped(to: inputImage.extent)
        
        let green = inputImage.applyingFilter("CIAffineTransform",
                                              parameters: [kCIInputTransformKey: NSValue(cgAffineTransform: greenTransform)])
            .cropped(to: inputImage.extent)
        
        let blue = inputImage.applyingFilter("CIAffineTransform",
                                             parameters: [kCIInputTransformKey: NSValue(cgAffineTransform: blueTransform)])
            .cropped(to: inputImage.extent)

        rgbChannelCompositing.inputRedImage = red
        rgbChannelCompositing.inputGreenImage = green
        rgbChannelCompositing.inputBlueImage = blue
        
        let finalImage = rgbChannelCompositing.outputImage
        
        return finalImage
    }
}

/// `RGBChannelGaussianBlur` allows Gaussian blur on a per channel basis

class RGBChannelGaussianBlur: CIFilter {
    var inputImage: CIImage?
    
    var inputRedRadius: CGFloat = 2
    var inputGreenRadius: CGFloat = 4
    var inputBlueRadius: CGFloat = 8
    
    let rgbChannelCompositing = RGBChannelCompositing()
    
    override func setDefaults() {
        inputRedRadius = 2
        inputGreenRadius = 4
        inputBlueRadius = 8
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputRedRadius":
            inputRedRadius = value as! CGFloat
        case "inputGreenRadius":
            inputGreenRadius = value as! CGFloat
        case "inputBlueRadius":
            inputBlueRadius = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }
    

    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "RGB Channel Gaussian Blur",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputRedRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 2,
                kCIAttributeDisplayName: "Red Radius",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputGreenRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 4,
                kCIAttributeDisplayName: "Green Radius",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputBlueRadius": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 8,
                kCIAttributeDisplayName: "Blue Radius",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 100,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    override var outputImage: CIImage! {
        guard let inputImage = inputImage else {
            return nil
        }
        
        let red = inputImage
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: inputRedRadius])
            .clampedToExtent()
        
        let green = inputImage
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: inputGreenRadius])
            .clampedToExtent()
        
        let blue = inputImage
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: inputBlueRadius])
            .clampedToExtent()
        
        rgbChannelCompositing.inputRedImage = red
        rgbChannelCompositing.inputGreenImage = green
        rgbChannelCompositing.inputBlueImage = blue
        
        return rgbChannelCompositing.outputImage
    }
}
