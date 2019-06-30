//
//  GrainFilter.swift
//  phixer
//
//  Created by Philip Price on 12/24/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to implement crop and rotate
// Note that the input rectangle must be in (CG) Image coordinates, not view coordinates

class GrainFilter: CIFilter {
    let fname = "Film Grain"
    var inputImage: CIImage?
    var inputAmount: CGFloat = 0.0
    var inputSize: CGFloat = 0.0
    
    // filters used to create effect. Static so that they can be re-used across instances
    private static var noiseFilter: CIFilter?  = nil
    private static var whiteningFilter: CIFilter?  = nil
    private static var darkeningFilter: CIFilter?  = nil
    private static var grayscaleFilter: CIFilter?  = nil
    private static var opacityFilter: CIFilter?  = nil
    private static var compositingFilter: CIFilter?  = nil
    private static var multiplyFilter: CIFilter?  = nil

    // default settings
    override func setDefaults() {
        inputImage = nil
        inputAmount = 0.0
        inputSize = 0.0
    }
    
    
    // filter display name
    func displayName() -> String {
        return fname
    }
    
    private func checkFilters() {
        if GrainFilter.noiseFilter == nil {
            GrainFilter.noiseFilter = CIFilter(name: "CIRandomGenerator")
            GrainFilter.whiteningFilter = CIFilter(name: "CIColorMatrix")
            GrainFilter.darkeningFilter = CIFilter(name: "CIColorMatrix")
            GrainFilter.compositingFilter = CIFilter(name: "CISourceOverCompositing")
            GrainFilter.grayscaleFilter = CIFilter(name:"CIMinimumComponent")
            GrainFilter.multiplyFilter = CIFilter(name: "CIMultiplyCompositing")
            GrainFilter.opacityFilter = CIFilter(name: "OpacityFilter")
       }
    }
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputAmount": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.5,
                           kCIAttributeDisplayName: "Grain Amount",
                           kCIAttributeMin: 0.0,
                           kCIAttributeSliderMin: 0.0,
                           kCIAttributeSliderMax: 1.0,
                           kCIAttributeType: kCIAttributeTypeScalar],
            
            "inputSize": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDefault: 0.5,
                           kCIAttributeDisplayName: "Grain Size",
                           kCIAttributeMin: 0.0,
                           kCIAttributeSliderMin: 0.0,
                           kCIAttributeSliderMax: 1.0,
                           kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }

    
    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        case "inputAmount":
            inputAmount = value as! CGFloat
        case "inputSize":
            inputSize = value as! CGFloat
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage else {
            log.error("NIL image supplied")
            return nil
        }
        
        checkFilters()
        guard GrainFilter.noiseFilter != nil else {
            log.error("NIL noise filter")
            return inputImage
        }

        // generate a noisy image
        let noiseImage = GrainFilter.noiseFilter?.outputImage
        guard noiseImage != nil else {
            log.error("NIL noise image")
            return inputImage
        }
        
        // Generate white speckles from the noise
        let noiseSize = 0.01*inputSize
        let whitenVector = CIVector(x: 0, y: 1, z: 0, w: 0)
        let grainVector = CIVector(x:0, y:noiseSize, z:0, w:0)
        let zeroVector = CIVector(x: 0, y: 0, z: 0, w: 0)

        GrainFilter.whiteningFilter?.setValue(noiseImage!, forKey: kCIInputImageKey)
        GrainFilter.whiteningFilter?.setValue(whitenVector, forKey: "inputRVector")
        GrainFilter.whiteningFilter?.setValue(whitenVector, forKey: "inputGVector")
        GrainFilter.whiteningFilter?.setValue(whitenVector, forKey: "inputBVector")
        GrainFilter.whiteningFilter?.setValue(grainVector, forKey: "inputAVector")
        GrainFilter.whiteningFilter?.setValue(zeroVector, forKey: "inputBiasVector")

        let whiteSpecks = GrainFilter.whiteningFilter?.outputImage
        guard whiteSpecks != nil else {
            log.error("NIL white specks image")
            return inputImage
        }

        // Blur the speckles a little
        let blurredImage = whiteSpecks?.applyingFilter("CIBoxBlur", parameters: ["inputRadius": 5.0]).clampedToExtent()

        
        // generate 'faded' versions of the white and dark images
        let opacity = inputAmount * 0.6 // full intensity doesn't look good so scale it down a bit (empirical value)
        GrainFilter.opacityFilter?.setValue(opacity, forKey: "inputOpacity")
        
        
        // scratches don't look good, so just return speckled image
        GrainFilter.opacityFilter?.setValue(blurredImage, forKey: "inputImage")
        
        // try soft light or overlay blend instead of source over composite:
        let fadedSpecksImage = GrainFilter.opacityFilter?.outputImage
        guard fadedSpecksImage != nil else {
            log.error("NIL faded speckles image")
            return inputImage
        }

        /***/
       // overlay onto the original image - Overlay seems to work best
        let overlayFilter = CIFilter(name:"CIOverlayBlendMode")
        overlayFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        overlayFilter?.setValue(fadedSpecksImage!, forKey: kCIInputBackgroundImageKey)
        let finalImage = overlayFilter?.outputImage
        guard finalImage != nil else {
            log.error("NIL sratched image")
            return inputImage
        }

         return finalImage?.cropped(to: inputImage.extent)
         /***/
        
        /***
          // the opacity filter can also do a source over composite
        GrainFilter.opacityFilter?.setValue(inputImage, forKey: "inputBackgroundImage")
        
        let finalImage = GrainFilter.opacityFilter?.outputImage
        if finalImage  == nil {
            return inputImage
        } else {
            return finalImage?.cropped(to: inputImage.extent)
       }
 ***/
        /***

        // generate dark scratches from the white speckled image
        let verticalScale = CGAffineTransform(scaleX: 1.5, y: 25)
        let transformedNoise = noiseImage?.transformed(by: verticalScale)
        
        let darkenVector = CIVector(x: 4, y: 0, z: 0, w: 0)
        let darkenBias = CIVector(x: 0, y: 1, z: 1, w: 1)
        
        GrainFilter.darkeningFilter?.setValue(transformedNoise!, forKey: kCIInputImageKey)
        GrainFilter.darkeningFilter?.setValue(darkenVector, forKey: "inputRVector")
        GrainFilter.darkeningFilter?.setValue(zeroVector, forKey: "inputGVector")
        GrainFilter.darkeningFilter?.setValue(zeroVector, forKey: "inputBVector")
        GrainFilter.darkeningFilter?.setValue(zeroVector, forKey: "inputAVector")
        GrainFilter.darkeningFilter?.setValue(darkenBias, forKey: "inputBiasVector")

        let randomScratches =  GrainFilter.darkeningFilter?.outputImage
        guard randomScratches != nil else {
            log.error("NIL dark scratches image")
            return inputImage
        }

        GrainFilter.opacityFilter?.setValue(whiteSpecks!, forKey: kCIInputImageKey)
        let fadedSpecksImage = GrainFilter.opacityFilter?.outputImage
        guard fadedSpecksImage != nil else {
            log.error("NIL faded speckles image")
            return inputImage
        }

        GrainFilter.opacityFilter?.setValue(randomScratches!, forKey: kCIInputImageKey)
        let fadedScratchesImage = GrainFilter.opacityFilter?.outputImage
        guard fadedScratchesImage != nil else {
            log.error("NIL faded scratches image")
            return inputImage
        }

        // overlay the speckles onto the input image
        GrainFilter.compositingFilter?.setValue(fadedSpecksImage!, forKey: kCIInputImageKey)
        GrainFilter.compositingFilter?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        let speckledImage = GrainFilter.compositingFilter?.outputImage
        guard speckledImage != nil else {
            log.error("NIL speckled image")
            return inputImage
        }

        // multiply by the scratches image
        GrainFilter.multiplyFilter?.setValue(fadedScratchesImage!, forKey: kCIInputImageKey)
        GrainFilter.multiplyFilter?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        let scratchedImage = GrainFilter.multiplyFilter?.outputImage
        guard scratchedImage != nil else {
            log.error("NIL sratched image")
            return inputImage
        }

        let finalImage = scratchedImage?.cropped(to: inputImage.extent)
         return finalImage
         ***/
        
    }
}
