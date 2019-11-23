//
//  FilmGrainFilter.swift
//  phixer
//
//  Created by Philip Price on 12/24/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter to implement crop and rotate
// Note that the input rectangle must be in (CG) Image coordinates, not view coordinates

class FilmGrainFilter: CIFilter {
    let fname = "Film Grain"
    var inputImage: CIImage?
    var inputAmount: CGFloat = 0.5
    var inputSize: CGFloat = 0.5
    
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
        inputAmount = 0.5
        inputSize = 0.5
    }
    
    
    // filter display name
    func displayName() -> String {
        return fname
    }
    
    private func checkFilters() {
        if FilmGrainFilter.noiseFilter == nil {
            FilmGrainFilter.noiseFilter = CIFilter(name: "CIRandomGenerator")
            FilmGrainFilter.whiteningFilter = CIFilter(name: "CIColorMatrix")
            FilmGrainFilter.darkeningFilter = CIFilter(name: "CIColorMatrix")
            FilmGrainFilter.compositingFilter = CIFilter(name: "CISourceOverCompositing")
            FilmGrainFilter.grayscaleFilter = CIFilter(name:"CIMinimumComponent")
            FilmGrainFilter.multiplyFilter = CIFilter(name: "CIMultiplyCompositing")
            FilmGrainFilter.opacityFilter = CIFilter(name: "OpacityFilter")
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
        guard FilmGrainFilter.noiseFilter != nil else {
            log.error("NIL noise filter")
            return inputImage
        }

        guard (inputAmount > 0.01) && (inputSize > 0.01) else { // don't bother applying
            return inputImage
        }
        
        // generate a noisy image
        let noiseImage = FilmGrainFilter.noiseFilter?.outputImage?
            //.applyingFilter("ScatterFilter", parameters: ["inputScatterRadius": 25*inputSize])
            .cropped(to: inputImage.extent).clampedToExtent()
        guard noiseImage != nil else {
            log.error("NIL noise image")
            return inputImage
        }
        
        //return noiseImage // DEBUG: check intermediate result
        
        // Generate white speckles from the noise (scaling is empirical)
        let noiseSize = 0.001*inputSize
        let whitenVector = CIVector(x: 0, y: 1, z: 0, w: 0)
        //let whitenVector = CIVector(x: 0, y: inputAmount, z: 0, w: 0)
        let grainVector = CIVector(x:0, y:noiseSize, z:0, w:0)
        let zeroVector = CIVector(x: 0, y: 0, z: 0, w: 0)

        FilmGrainFilter.whiteningFilter?.setValue(noiseImage!, forKey: kCIInputImageKey)
        FilmGrainFilter.whiteningFilter?.setValue(whitenVector, forKey: "inputRVector")
        FilmGrainFilter.whiteningFilter?.setValue(whitenVector, forKey: "inputGVector")
        FilmGrainFilter.whiteningFilter?.setValue(whitenVector, forKey: "inputBVector")
        FilmGrainFilter.whiteningFilter?.setValue(grainVector, forKey: "inputAVector")
        FilmGrainFilter.whiteningFilter?.setValue(zeroVector, forKey: "inputBiasVector")

        let whiteSpecks = FilmGrainFilter.whiteningFilter?.outputImage?
            .applyingFilter("ScatterFilter", parameters: ["inputScatterRadius": 10*inputSize])
            .applyingFilter("BrightnessFilter", parameters: ["inputBrightness": min(-0.4, (inputAmount-1.0))])
            .applyingFilter("OpacityFilter", parameters: ["inputOpacity": 0.2*inputAmount])
            .cropped(to: inputImage.extent).clampedToExtent()
        guard whiteSpecks != nil else {
            log.error("NIL white specks image")
            return inputImage
        }
        
        //return whiteSpecks // DEBUG: check intermediate result
        
        // Blur the speckles a little
        //let blurredImage = whiteSpecks?.applyingFilter("CIBoxBlur", parameters: ["inputRadius": 2.0*inputSize]).cropped(to: inputImage.extent).clampedToExtent()
        //let blurredImage = whiteSpecks?.applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 2.0*inputSize]).cropped(to: inputImage.extent).clampedToExtent()

        let blurredImage = whiteSpecks
        //return blurredImage // DEBUG: check intermediate result

        /****/
        // generate 'faded' versions of the white speckles image
        let opacity = min(0.6, inputAmount)
        //let opacity = 0.2 // full intensity doesn't look good so scale it down a bit (empirical value)
        FilmGrainFilter.opacityFilter?.setValue(opacity, forKey: "inputOpacity")
        FilmGrainFilter.opacityFilter?.setValue(blurredImage, forKey: "inputImage")
        
        let fadedSpecksImage = FilmGrainFilter.opacityFilter?.outputImage?.cropped(to: inputImage.extent).clampedToExtent()
        guard fadedSpecksImage != nil else {
            log.error("NIL faded speckles image")
            return inputImage
        }
        /***/


        //let fadedSpecksImage = blurredImage
        
        //return fadedSpecksImage // DEBUG: check intermediate result
        
       // overlay onto the original image - Overlay Blend Mode seems to work best
        //let overlayFilter = CIFilter(name:"CISourceOverCompositing")
        //let overlayFilter = CIFilter(name:"CIOverlayBlendMode")
        //let overlayFilter = CIFilter(name:"CISoftLightBlendMode")
        //let overlayFilter = CIFilter(name:"CIScreenBlendMode")
        let overlayFilter = CIFilter(name:"CILuminosityBlendMode")
        overlayFilter?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        overlayFilter?.setValue(fadedSpecksImage!, forKey: kCIInputImageKey)
        let speckledImage = overlayFilter?.outputImage?.cropped(to: inputImage.extent).clampedToExtent()
        guard speckledImage != nil else {
            log.error("NIL speckled image")
            return inputImage
        }

         //return speckledImage // DEBUG: check intermediate result

        /***/

        // generate dark scratches from the white speckled image
        //let verticalScale = CGAffineTransform(scaleX: 1.5, y: 25)
        let verticalScale = CGAffineTransform(scaleX: 1.0+inputSize, y: 1.5 + 5.0*(1.0+inputSize))
        let transformedNoise = noiseImage?.transformed(by: verticalScale)
        
        let darkenVector = CIVector(x: 4, y: 0, z: 0, w: 0)
        let darkenBias = CIVector(x: 0, y: 1, z: 1, w: 1)
        
        FilmGrainFilter.darkeningFilter?.setValue(transformedNoise!, forKey: kCIInputImageKey)
        FilmGrainFilter.darkeningFilter?.setValue(darkenVector, forKey: "inputRVector")
        FilmGrainFilter.darkeningFilter?.setValue(zeroVector, forKey: "inputGVector")
        FilmGrainFilter.darkeningFilter?.setValue(zeroVector, forKey: "inputBVector")
        FilmGrainFilter.darkeningFilter?.setValue(zeroVector, forKey: "inputAVector")
        FilmGrainFilter.darkeningFilter?.setValue(darkenBias, forKey: "inputBiasVector")

        let randomScratches =  FilmGrainFilter.darkeningFilter?.outputImage?.cropped(to: inputImage.extent).clampedToExtent()
        guard randomScratches != nil else {
            log.error("NIL dark scratches image")
            return inputImage
        }

        // The resulting scratches are cyan-colored, so grayscale them using the CIMinimumComponentFilter, which takes the
        // minimum of the RGB values to produce a grayscale image.
        let darkScratches = randomScratches?.applyingFilter("CIMinimumComponent", parameters: [ kCIInputImageKey: randomScratches ])
        
        //return darkScratches // DEBUG: check intermediate result

        /***
        FilmGrainFilter.opacityFilter?.setValue(darkScratches!, forKey: kCIInputImageKey)
        let fadedScratchesImage = FilmGrainFilter.opacityFilter?.outputImage
        guard fadedScratchesImage != nil else {
            log.error("NIL faded scratches image")
            return inputImage
        }
         ***/
        let fadedScratchesImage = darkScratches

        //return fadedScratchesImage // DEBUG: check intermediate result
        
        // multiply by the scratches image
        FilmGrainFilter.multiplyFilter?.setValue(fadedScratchesImage!, forKey: kCIInputImageKey)
        FilmGrainFilter.multiplyFilter?.setValue(speckledImage, forKey: kCIInputBackgroundImageKey)
        let scratchedImage = FilmGrainFilter.multiplyFilter?.outputImage
        guard scratchedImage != nil else {
            log.error("NIL sratched image")
            return inputImage
        }

         //return scratchedImage // DEBUG: check intermediate result
        
        // reduce the opacity based on inputAmount
        FilmGrainFilter.opacityFilter?.setValue(scratchedImage!, forKey: kCIInputImageKey)
        FilmGrainFilter.opacityFilter?.setValue(inputAmount, forKey: "inputOpacity")
        let fadedImage = FilmGrainFilter.opacityFilter?.outputImage
        guard fadedImage != nil else {
            log.error("NIL faded image")
            return inputImage
        }
        
        // we have a somewhat transparent scratched/speckled image, so overlay onto the original
        //let overlayFilter2 = CIFilter(name:"CIOverlayBlendMode")
        let overlayFilter2 = CIFilter(name:"CISourceOverCompositing")
        overlayFilter2?.setValue(fadedImage!, forKey: kCIInputImageKey)
        overlayFilter2?.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
        let finalImage = overlayFilter2?.outputImage
        guard finalImage != nil else {
            log.error("NIL speckled image")
            return inputImage
        }

        return finalImage!.cropped(to: inputImage.extent)
        
    }
}
