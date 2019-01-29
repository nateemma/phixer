//
//  CRTFilter.swift
//  Filterpedia
//
//  CRT filter and VHS Tracking Lines
//
//  Created by Simon Gladman on 20/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import CoreImage

class VHSTrackingLines: CIFilter
{
    var inputImage: CIImage?
    var inputTime: CGFloat = 0
    var inputSpacing: CGFloat = 50
    var inputStripeHeight: CGFloat = 0.5
    var inputBackgroundNoise: CGFloat = 0.05
    
    override func setDefaults()
    {
        inputSpacing = 50
        inputStripeHeight = 0.5
        inputBackgroundNoise = 0.05
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputSpacing":
            inputSpacing = value as! CGFloat
        case "inputStripeHeight":
            inputStripeHeight = value as! CGFloat
        case "inputBackgroundNoise":
            inputBackgroundNoise = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "VHS Tracking Lines",
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            "inputTime": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 8,
                kCIAttributeDisplayName: "Time",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 2048,
                kCIAttributeType: kCIAttributeTypeScalar],
            "inputSpacing": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 50,
                kCIAttributeDisplayName: "Spacing",
                kCIAttributeMin: 20,
                kCIAttributeSliderMin: 20,
                kCIAttributeSliderMax: 200,
                kCIAttributeType: kCIAttributeTypeScalar],
            "inputStripeHeight": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.5,
                kCIAttributeDisplayName: "Stripe Height",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar],
            "inputBackgroundNoise": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.05,
                kCIAttributeDisplayName: "Background Noise",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 0.25,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    override var outputImage: CIImage?
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        let tx = NSValue(cgAffineTransform: CGAffineTransform(translationX: CGFloat(drand48() * 100), y: CGFloat(drand48() * 100)))
        
        let noise = CIFilter(name: "CIRandomGenerator")!.outputImage!
            .applyingFilter("CIAffineTransform",
                            parameters: [kCIInputTransformKey: tx])
            .applyingFilter("CILanczosScaleTransform",
                            parameters: [kCIInputAspectRatioKey: 5])
            .cropped(to: inputImage.extent)
        
        
        let kernel = CIColorKernel(source:
            "kernel vec4 thresholdFilter(__sample image, __sample noise, float time, float spacing, float stripeHeight, float backgroundNoise)" +
                "{" +
                "   vec2 uv = destCoord();" +
                
                "   float stripe = smoothstep(1.0 - stripeHeight, 1.0, sin((time + uv.y) / spacing)); " +
                
                "   return image + (noise * noise * stripe) + (noise * backgroundNoise);" +
            "}"
            )!
        
        
        let extent = inputImage.extent
        let arguments = [inputImage, noise, inputTime, inputSpacing, inputStripeHeight, inputBackgroundNoise] as [Any]
        
        let final = kernel.apply(extent: extent, arguments: arguments)?
            //.imageByApplyingFilter("CIPhotoEffectNoir", withInputParameters: nil)
            .applyingFilter("CIPhotoEffectNoir")

        return final
    }
}


class CRTFilter: CIFilter
{
    var inputImage : CIImage?
    var inputPixelWidth: CGFloat = 8
    var inputPixelHeight: CGFloat = 12
    var inputBend: CGFloat = 3.2
    
    override var attributes: [String : Any]
    {
        return [
            kCIAttributeFilterDisplayName: "CRT Filter",
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            "inputPixelWidth": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 8,
                kCIAttributeDisplayName: "Pixel Width",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 20,
                kCIAttributeType: kCIAttributeTypeScalar],
            "inputPixelHeight": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 12,
                kCIAttributeDisplayName: "Pixel Height",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 20,
                kCIAttributeType: kCIAttributeTypeScalar],
            "inputBend": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 3.2,
                kCIAttributeDisplayName: "Bend",
                kCIAttributeMin: 0.5,
                kCIAttributeSliderMin: 0.5,
                kCIAttributeSliderMax: 10,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    let crtWarpFilter = CRTWarpFilter()
    let crtColorFilter = CRTColorFilter()
    
    let vignette = CIFilter(name: "CIVignette", parameters: [ kCIInputIntensityKey: 1.5, kCIInputRadiusKey: 2])!
    
    override func setDefaults()
    {
        inputPixelWidth = 8
        inputPixelHeight = 12
        inputBend = 3.2
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputPixelWidth":
            inputPixelWidth = value as! CGFloat
        case "inputPixelHeight":
            inputPixelHeight = value as! CGFloat
        case "inputBend":
            inputBend = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        crtColorFilter.setValue(inputImage, forKey: "inputImage")
        crtColorFilter.setValue(inputPixelHeight, forKey: "inputPixelHeight")
        crtColorFilter.setValue(inputPixelHeight, forKey: "inputPixelWidth")
        
        crtWarpFilter.setValue(inputImage, forKey: "inputImage")
        crtWarpFilter.setValue(inputBend, forKey: "inputBend")
        
        let crtimage = crtColorFilter.outputImage
        guard crtimage != nil else {
            log.error("NIL CRT image returned from CRTColorFilter")
            return nil
        }
        
        vignette.setValue(crtimage, forKey: kCIInputImageKey)
        let vimage = vignette.outputImage
        guard vimage != nil else {
            log.error("NIL image returned from Vignette Filter")
            return nil
        }
        crtWarpFilter.inputImage = vimage!
        return crtWarpFilter.outputImage
        
    }
    
    
    
    
    class CRTColorFilter: CIFilter
    {
        var inputImage : CIImage?
        
        var inputPixelWidth: CGFloat = 8.0
        var inputPixelHeight: CGFloat = 12.0
        
        override func setValue(_ value: Any?, forKey key: String) {
            switch key {
            case "inputImage":
                inputImage = value as? CIImage
            case "inputPixelWidth":
                inputPixelWidth = value as! CGFloat
            case "inputPixelHeight":
                inputPixelHeight = value as! CGFloat
            default:
                log.error("Invalid key: \(key)")
            }
        }

        override var attributes: [String : Any]
        {
            return [
                kCIAttributeFilterDisplayName: "CRT Color Filter",
                "inputImage": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "CIImage",
                               kCIAttributeDisplayName: "Image",
                               kCIAttributeType: kCIAttributeTypeImage],
                "inputPixelWidth": [kCIAttributeIdentity: 0,
                                    kCIAttributeClass: "NSNumber",
                                    kCIAttributeDefault: 8,
                                    kCIAttributeDisplayName: "Pixel Width",
                                    kCIAttributeMin: 0,
                                    kCIAttributeSliderMin: 0,
                                    kCIAttributeSliderMax: 20,
                                    kCIAttributeType: kCIAttributeTypeScalar],
                "inputPixelHeight": [kCIAttributeIdentity: 0,
                                     kCIAttributeClass: "NSNumber",
                                     kCIAttributeDefault: 12,
                                     kCIAttributeDisplayName: "Pixel Height",
                                     kCIAttributeMin: 0,
                                     kCIAttributeSliderMin: 0,
                                     kCIAttributeSliderMax: 20,
                                     kCIAttributeType: kCIAttributeTypeScalar]
            ]
        }

        //let crtColorKernel = CIColorKernel(source:
        let crtKernel = CIKernel(source:
            "kernel vec4 crtColor(sampler image, float pixelWidth, float pixelHeight) \n" +
                "{ \n" +
                
                "   int columnIndex = int(mod(samplerCoord(image).x / pixelWidth, 3.0)); \n" +
                "   int rowIndex = int(mod(samplerCoord(image).y, pixelHeight)); \n" +
                
                "   float scanlineMultiplier = (rowIndex == 0 || rowIndex == 1) ? 0.3 : 1.0;\n" +
                
                "   float red = (columnIndex == 0) ? sample(image, samplerCoord(image)).r : sample(image, samplerCoord(image)).r * ((columnIndex == 2) ? 0.3 : 0.2); \n" +
                "   float green = (columnIndex == 1) ? sample(image, samplerCoord(image)).g : sample(image, samplerCoord(image)).g * ((columnIndex == 2) ? 0.3 : 0.2); \n" +
                "   float blue = (columnIndex == 2) ? sample(image, samplerCoord(image)).b : sample(image, samplerCoord(image)).b * 0.2; \n" +
                
                "   return vec4(red * scanlineMultiplier, green * scanlineMultiplier, blue * scanlineMultiplier, 1.0); \n" +
            "}"
        )
        
        
        override var outputImage: CIImage!
        {
            if let inputImage = inputImage,
                //let crtColorKernel = crtColorKernel
            let crtKernel = crtKernel
            {
                let dod = inputImage.extent
                //let args = [inputImage, inputPixelWidth, inputPixelHeight] as [Any]
                let args = [inputImage, inputPixelWidth, inputPixelHeight] as [Any]
                //return crtKernel.apply(extent: dod, arguments: args)
                return crtKernel.apply(extent: dod,
                                           roiCallback: { (index, rect) in return rect },
                                           arguments: args)
            }
            return nil
        }
    }
    
    
    
    class CRTWarpFilter: CIFilter
    {
        var inputImage : CIImage?
        var inputBend: CGFloat = 3.2
        
        override var attributes: [String : Any]
        {
            return [
                kCIAttributeFilterDisplayName: "CRT Warp Filter",
                "inputImage": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "CIImage",
                               kCIAttributeDisplayName: "Image",
                               kCIAttributeType: kCIAttributeTypeImage],
                "inputBend": [kCIAttributeIdentity: 0,
                              kCIAttributeClass: "NSNumber",
                              kCIAttributeDefault: 3.2,
                              kCIAttributeDisplayName: "Bend",
                              kCIAttributeMin: 0.5,
                              kCIAttributeSliderMin: 0.5,
                              kCIAttributeSliderMax: 10,
                              kCIAttributeType: kCIAttributeTypeScalar]
            ]
        }
        
        override func setValue(_ value: Any?, forKey key: String) {
            switch key {
            case "inputImage":
                inputImage = value as? CIImage
            case "inputBend":
                inputBend = value as! CGFloat
            default:
                log.error("Invalid key: \(key)")
            }
        }

        let crtWarpKernel = CIWarpKernel(source:
            "kernel vec2 crtWarp(vec2 extent, float bend)" +
                "{" +
                "   vec2 coord = ((destCoord() / extent) - 0.5) * 2.0;" +
                
                "   coord.x *= 1.0 + pow((abs(coord.y) / bend), 2.0);" +
                "   coord.y *= 1.0 + pow((abs(coord.x) / bend), 2.0);" +
                
                "   coord  = ((coord / 2.0) + 0.5) * extent;" +
                
                "   return coord;" +
            "}"
        )
        
        override var outputImage : CIImage! {
            if let inputImage = inputImage,
                let crtWarpKernel = crtWarpKernel {
                let arguments = [CIVector(x: inputImage.extent.size.width, y: inputImage.extent.size.height), inputBend] as [Any]
                let extent = inputImage.extent.insetBy(dx: -1, dy: -1)
                
                return crtWarpKernel.apply(extent: extent,
                                           roiCallback: { (index, rect) in return rect },
                                           image: inputImage,
                                           arguments: arguments)
            }
            return nil
        }
    }
}

