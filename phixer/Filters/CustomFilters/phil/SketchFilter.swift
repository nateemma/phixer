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
    
    var parameterChanged:Bool = false

    //private let kernel: CIKernel!
    var currOutputImage:CIImage? = nil
    
    static var pencilTexture:CIImage? = nil
    
    // filter display name
    func displayName() -> String {
        return "Sketch Edge Detection"
    }

    // init
    override init() {
        /****
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
 ****/
        super.init()
        
        if SketchFilter.pencilTexture == nil {
            SketchFilter.loadPencilTexture()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // default settings
    override func setDefaults() {
        inputImage = nil
        inputThreshold = 0.5
        inputMix = 0.5
        inputTexture = 0.5
        parameterChanged = true
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
                               kCIAttributeDisplayName: "Edges",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.01,
                               kCIAttributeSliderMax: 1.0,
                               kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputMix": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.5,
                               kCIAttributeDisplayName: "Detail",
                               kCIAttributeMin: 0,
                               kCIAttributeSliderMin: 0.01,
                               kCIAttributeSliderMax: 1.0,
                               kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputTexture": [kCIAttributeIdentity: 0,
                               kCIAttributeClass: "NSNumber",
                               kCIAttributeDefault: 0.5,
                               kCIAttributeDisplayName: "Shading",
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
            parameterChanged = true
           prepInput()
        case "inputThreshold":
            let v = value as! CGFloat
            if !v.approxEqual(inputThreshold){
                inputThreshold = v
                parameterChanged = true
                prepEdges()
            }
        case "inputMix":
            let v = value as! CGFloat
            if !v.approxEqual(inputMix){
                inputMix = v
                parameterChanged = true
                prepDetail()
            }
        case "inputTexture":
            let v = value as! CGFloat
            if !v.approxEqual(inputTexture){
                inputTexture = v
                parameterChanged = true
                prepShading()
            }
        default:
            log.error("Invalid key: \(key)")
        }
        
    }

    
    // class-level vars because we need them to persist across calls:
    private var resizedInputImg:CIImage? = nil        // resized version of the input (don't need/want full resoultion for sketch)
    private var workingExtent:CGRect = CGRect.zero    // extent of the downsized (working) image
    private var shadingTextureImg:CIImage? = nil      // the image used to generate shading
    private var monoImg:CIImage? = nil                // B&W version of the input
    private var basicSketchImg:CIImage? = nil         // basic sketch conversion, i.e. without shading and edges
    private var shadedImg:CIImage? = nil              // shading overlay
    private var edgeImg:CIImage? = nil                // edges overlay

    
    // this is called when an app accesses the ouputImage var
    
    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            log.error("No input image")
            return nil
        }
        
        // only run the filter if something changed (or this is the first run)
        if (parameterChanged) {
            parameterChanged = false
            
            combineLayers()
        }
        
        return currOutputImage
    }
    
    
    
    
    // load the texture to be used for the pencil shading effect
    static func loadPencilTexture(){
        
        log.debug("Loading pencil texture")
        
        let url = Bundle.main.url(forResource: "tx_pencil_crosshatch_2", withExtension: "jpg")
        if url != nil {
            SketchFilter.pencilTexture = CIImage(contentsOf: url!)
        } else {
            log.error("Could not load pencil texture")
        }
    }

    
    
    
    // sets up vars that only need to be changed when the input changes
     private func prepInput(){
        guard let inputImage = inputImage else {
            log.error("No input image")
            return
        }
        
        log.debug("Processing input file")
        
        // resize so that longest is edge is at most 1024 pixels
        let l = max(inputImage.extent.size.width, inputImage.extent.size.height)
        if l > 1024.0 {
            let ratio = 1024.0 / l
            let size = CGSize(width: inputImage.extent.size.width*ratio, height: inputImage.extent.size.height*ratio)
            resizedInputImg = inputImage.resize(size: size)!
        } else {
            resizedInputImg = inputImage
        }
        workingExtent = (resizedInputImg?.extent)!
        
        // resize the pencil texture to match
        shadingTextureImg = SketchFilter.pencilTexture?.resize(size: workingExtent.size)

        // equalise, bump up the contrast, convert to B&W
        monoImg = resizedInputImg?
            .applyingFilter("YUCIHistogramEqualization")
            .applyingFilter("ClarityFilter")
            //.applyingFilter("CIColorControls", parameters: ["inputContrast": 1.0])
            //.applyingFilter("CIColorPosterize", parameters: ["inputLevels": 16])
            .applyingFilter("CIPhotoEffectMono")

        // set the other class-scope vars so that they are not nil
        basicSketchImg = monoImg
        shadedImg = monoImg
        edgeImg = monoImg

        // since the input has changed, call the other prep funcs. This ensures filter will be ready if defaults are used
        prepDetail()
        prepShading()
        prepEdges()
        combineLayers()

    }
    
    
    
    // set up vars that change when the mix threshold is changed
    private func prepDetail(){
 
        log.debug("Generating basic sketch")

        guard let monoImg = monoImg else {
            log.error("prepped images not available")
            return
        }
        
/*** debug version:
        // create the inverse of the mono image and blur it
        let img2 = monoImg.applyingFilter("CIColorInvert")
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 20.0 * inputMix])
            .clampedToExtent()
            .cropped(to: workingExtent)
        
        // blend the mono image and its inverse. This gives a very basic sketch effect
        let img3 =  img2.applyingFilter("CILinearDodgeBlendMode", parameters: [kCIInputBackgroundImageKey:monoImg])
        //.applyingFilter("CIColorControls", parameters: ["inputBrightness": -0.7, "inputContrast": 1.0])
        
        // make lines darker
        basicSketchImg = img3.applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:img3])
 ***/
        
        // chained version:
        let tmpImg = monoImg.applyingFilter("CIColorInvert")
            //.applyingFilter("CIBoxBlur", parameters: ["inputRadius": 20.0 * inputMix])
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 20.0 * inputMix])
            .clampedToExtent()
            .cropped(to: workingExtent)
            .applyingFilter("CILinearDodgeBlendMode", parameters: [kCIInputBackgroundImageKey:monoImg])
            
        basicSketchImg = tmpImg.applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:tmpImg])

    }
    
    
    
    // set up vars that change when the texture amount is changed
    private func prepShading(){
        
 
        guard let monoImg = monoImg, let shadingTextureImg = shadingTextureImg  else {
            log.error("prepped images not available")
            return
        }
        
        log.debug("Generating shading")

        // create an overlay of the basic sketch and the pencil texture

        // create a mask from the b&w image by selecting the dark regions
        let shadowMask = monoImg.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.0, "inputUpper": 0.1])
            .applyingFilter("CIColorInvert")
        
        //TODO: create masks of different areas/depths of darkness?
        
        // darken the shading texture, mask it, blend with the basic sketch and turn down the opacity based on the user input
        shadedImg = shadingTextureImg
            .applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey: shadingTextureImg.applyingFilter("OpacityFilter", parameters:  ["inputOpacity": 0.2])])
            .applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: shadowMask, kCIInputBackgroundImageKey: shadingTextureImg])
            .applyingFilter("CIBlendWithMask", parameters: [kCIInputMaskImageKey: shadowMask, kCIInputBackgroundImageKey: basicSketchImg])
            .applyingFilter("OpacityFilter", parameters:  ["inputOpacity": inputTexture])

               // TODO: add light opacity overlay of mono image?
    }
    
    
    // set up vars that change when edge threshold is changed
    private func prepEdges(){
        
        log.debug("Generating edges")
        

        // generate the edges, with some blurring and slightly reduced opacity
        // Note: using colour image because edges can be lost if using the B&W version
        
        // Notes: - SobelFilter needs to be inverted, Sobel3x3 does not
        //        - Sobel3x3 has much stronger edge detection, so bring down the opacity if using
        //        - BoxBlur is faster than Gaussian Blur
        //        - the Gloom filter softens edges and adds a glow effect
        edgeImg = inputImage?
            .applyingFilter("CIColorControls", parameters: ["inputContrast": 1.0])
            .applyingFilter("SobelFilter", parameters: ["inputThreshold": inputThreshold]).applyingFilter("CIColorInvert")
            //.applyingFilter("Sobel3x3Filter", parameters: ["inputThreshold": inputThreshold])
            //.applyingFilter("LumaRangeFilter", parameters: ["inputLower": 0.0, "inputUpper": 0.5])
            //.applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 1.0]).clampedToExtent()
            //.applyingFilter("CIBoxBlur", parameters: ["inputRadius": 1.0]).clampedToExtent()
            //.cropped(to: workingExtent)
            .applyingFilter("CIGloom", parameters:  ["inputRadius": 2.0, "inputIntensity": 1.0])
            .cropped(to: workingExtent)
           .applyingFilter("OpacityFilter", parameters:  ["inputOpacity": 0.6])


    }
    
    private func combineLayers(){
        log.debug("Combining layers")
        
        guard let basicSketchImg = basicSketchImg, let shadedImg = shadedImg, let edgeImg = edgeImg else {
            log.error("prepped images not available")
            currOutputImage = inputImage
            return
        }

        // OK, so we have a basic sketch, shading and edges, so combine them
        // Note: need to resize back to match the input image
        currOutputImage = basicSketchImg
            .applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey: shadedImg])
            .applyingFilter("CIMultiplyBlendMode", parameters: [kCIInputBackgroundImageKey:edgeImg])
            .resize(size: (inputImage?.extent.size)!)
    }
}
