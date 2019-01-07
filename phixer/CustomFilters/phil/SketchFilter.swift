//
//  SketchFilter.swift
//  phixer
//
//  Created by Philip Price on 01/04/19.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

class SketchFilter: CIFilter {
    var inputImage: CIImage?
    var inputThreshold: CGFloat = 0.5
    var inputMix: CGFloat = 0.5
    var inputTexture: CGFloat = 0.5

    private let kernel: CIKernel!
    
    
    // filter display name
    func displayName() -> String {
        return "Sketch Edge Detection"
    }

    // init
    override init() {
        do {

            
            // custom version based on GPUImage2 by Brad Larsen
            kernel = CIKernel(source:
                "kernel vec4 sobelFilter(sampler image, float threshold) {" +
                    "  mat3 sobel_x = mat3( -1, -2, -1, 0, 0, 0, 1, 2, 1 );" +
                    "  mat3 sobel_y = mat3( 1, 0, -1, 2, 0, -2, 1, 0, -1 );" +
                    "  float s_x = 0.0;" +
                    "  float s_y = 0.0;" +
                    "  vec2 dc = destCoord();" +
                    "  for (int i=-1; i <= 1; i++) {" +
                    "    for (int j=-1; j <= 1; j++) {" +
                    "      vec4 currentSample = sample(image, samplerTransform(image, dc + vec2(i,j)));" +
                    "      s_x += sobel_x[j+1][i+1] * currentSample.g;" +
                    "      s_y += sobel_y[j+1][i+1] * currentSample.g;" +
                    "    }" +
                    "  }" +
                    "  float mag = 1.0 - length(vec2 (s_x, s_y)) * threshold;" +
                    "  return vec4(mag, mag, mag, 1.0);" +
                "}"
            )

            
            if kernel == nil {
                log.error("Could not create CIColorKernel")
            }
        } catch {
            log.error("Could not create filter. Error: \(error)")
        }
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputThreshold = 5.0
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputThreshold": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.5,
                               kCIAttributeDisplayName: "EdgeThreshold",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.01,
                               kCIAttributeSliderMax: 1.0,
                               kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputMix": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.5,
                               kCIAttributeDisplayName: "Mix",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.01,
                               kCIAttributeSliderMax: 1.0,
                               kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputTexture": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.5,
                               kCIAttributeDisplayName: "Texture",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.01,
                               kCIAttributeSliderMax: 1.0,
                               kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputThreshold":
            inputThreshold = value as! CGFloat
        case "inputMix":
            inputMix = value as! CGFloat
        case "inputTexture":
            inputTexture = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage, let kernel = kernel else {
            log.error("No input image")
            return nil
        }
        
        //log.debug("threshold: \(inputThreshold)")
        
        /**
        let extent = inputImage.extent
        let arguments = [inputImage, inputThreshold] as [Any]
        
        return kernel.apply(extent: extent,
                            roiCallback: { (index, rect) in return rect },
                            arguments: arguments)
**/
/*** Attempt 1: use edge detection and invert:
        // TODO: try mixing under- and 0ver-exposed versions? Problems getting midtones with portraits
        let edgeImg = inputImage.applyingFilter("Sobel5x5Filter", parameters: ["inputThreshold": inputThreshold])
            .applyingFilter("CIColorInvert")
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 0.5])
        
        return edgeImg

 ***/
        
/*** Attempt 1a: bledge edge image with a 'hashed' image of the md tones
 
        // try compositing with the midtones, using different angles for different tones
        // NOTE: works, but looks like a print, not a sketch
        // Maybe run again on sketched image?

        let img1 = inputImage.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.0, "inputUpper": 0.01])
            .applyingFilter("CILineScreen", parameters: ["inputAngle": -0.303, "inputWidth": 4, "inputSharpness":0.1])
            .applyingFilter("CILineScreen", parameters: ["inputAngle": 0.303, "inputWidth": 4, "inputSharpness":0.1])
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.0])

        let img2 = inputImage.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.011, "inputUpper": 0.3])
            .applyingFilter("CILineScreen", parameters: ["inputAngle": 0.606, "inputWidth": 8, "inputSharpness":0.1])
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.0])

        let img3 = inputImage.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.21, "inputUpper": 0.45])
            .applyingFilter("CILineScreen", parameters: ["inputAngle": -0.606, "inputWidth": 8, "inputSharpness":0.1])
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.0])

        let img4 = inputImage.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.4, "inputUpper": 0.74])
            .applyingFilter("CILineScreen", parameters: ["inputAngle": 0.707, "inputWidth": 8, "inputSharpness":0.1])
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.0])

        let img5 = inputImage.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.7, "inputUpper": 0.99])
            .applyingFilter("CILineScreen", parameters: ["inputAngle": -0.707, "inputWidth": 10, "inputSharpness":0.1])
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.0])


        let midtoneImage = img1.applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:img2])
            .applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:img3])
            .applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:img4])
            .applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:img5])
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.0])
            .applyingFilter("LaplacianGaussianFilter", parameters: ["inputThreshold": inputThreshold])
            .applyingFilter("CIColorInvert")
            .applyingFilter("OpacityFilter", parameters:  ["inputOpacity": 0.8])

        return edgeImg.applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:midtoneImage])
***/

/*** Attempt 2: use dodge blend mode on B&W version
 ***/
        
        //TODO: pre-allocated custom filters during init *******
        
        // resize so that longest is edge is at most 1024 pixels
        var srcImg = inputImage
        let l = max(inputImage.extent.size.width, inputImage.extent.size.height)
        if l > 1024.0 {
            let ratio = 1024.0 / l
            let size = CGSize(width: inputImage.extent.size.width*ratio, height: inputImage.extent.size.height*ratio)
            srcImg = inputImage.resize(size: size)!
        }
        
        // convert to B&W, invert and blend using Linear (or Color) Dodge
        let img1 = srcImg
            .applyingFilter("CIColorPosterize", parameters: ["inputLevels": 16])
            .applyingFilter("CIPhotoEffectMono")
        
        let img2 = img1.applyingFilter("CIColorInvert")
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 20.0 * inputMix])
            .cropped(to: img1.extent)
        
        let img3 =  img2.applyingFilter("CILinearDodgeBlendMode", parameters: [kCIInputBackgroundImageKey:img1])
            //.applyingFilter("CIColorControls", parameters: ["inputBrightness": -0.7, "inputContrast": 1.0])
        
        // make lines darker
        let basicSketchImg = img3.applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:img3])
        
        //return basicSketchImg //tmp dbg
        
        // overlay the edges, with some blurring
        let edgeImg = srcImg
            .applyingFilter("CIColorControls", parameters: ["inputContrast": 1.0])
            .applyingFilter("SobelFilter", parameters: ["inputThreshold": inputThreshold])
            .applyingFilter("CIColorInvert")
            //.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.0, "inputUpper": 0.5])
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.0])
            .applyingFilter("OpacityFilter", parameters:  ["inputOpacity": 0.8])
            .cropped(to: srcImg.extent)

        //return edgeImg // tmp debug
        
        // crate an overlay from the edges
        var texturedImg = basicSketchImg
        var url = Bundle.main.url(forResource: "tx_pencil_crosshatch_2", withExtension: "jpg")
        if url != nil {
            let texture = CIImage(contentsOf: url!)?
                .resize(size: basicSketchImg.extent.size)?
                .applyingFilter("OpacityFilter", parameters:  ["inputOpacity": inputTexture])
            if texture != nil {
                texturedImg = (basicSketchImg.applyingFilter("CISoftLightBlendMode", parameters: [kCIInputBackgroundImageKey: texture!]))
                    //.applyingFilter("CIColorControls", parameters: ["inputBrightness": 0.4])
            }
        }
        
        // create textured overlay for shadows (they are currently white), maybe with dark pencil texture
        // blend the textured sketch with the edges overlay
        var shadowImg = texturedImg
        url = Bundle.main.url(forResource: "tx_pencil_crosshatch_2", withExtension: "jpg")
        if url != nil {
            let texture = CIImage(contentsOf: url!)?
                .resize(size: basicSketchImg.extent.size)?
                .applyingFilter("CIColorControls", parameters: ["inputBrightness": -0.6])
              .applyingFilter("OpacityFilter", parameters:  ["inputOpacity": inputTexture*4])
            if texture != nil {
                shadowImg = img1.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.0, "inputUpper": 0.1])
                    .applyingFilter("CISoftLightBlendMode", parameters: [kCIInputBackgroundImageKey: texture!])
                    .applyingFilter("CISoftLightBlendMode", parameters: [kCIInputBackgroundImageKey: texturedImg])
                //.applyingFilter("CIColorControls", parameters: ["inputBrightness": 0.4])
            }
        }

        return shadowImg.applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:edgeImg])
    }
}
