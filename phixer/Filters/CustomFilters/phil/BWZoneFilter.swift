//
//  BWZoneFilter.swift
//  phixer
//
//  Created by Philip Price on 2/10/19
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// filter that converts an image to 11 b&w 'zones'
class BWZoneFilter: CIFilter {
    
    var inputImage: CIImage?

    // this kernel converts image colours to B&W 'zone' values, based on Ansel Adams Zone system
    
    // Note: lots of playing around with different ways to calculate luminosity. I left the variations in here (commented out) for reference
    
    let kernel = CIColorKernel(source:
        "vec3 rgb2hsv(vec3 c)\n" +
            "{\n" +
            "    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);\n" +
            "    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));\n" +
            "    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));\n" +
            "    float d = q.x - min(q.w, q.y);\n" +
            "    float e = 1.0e-10;\n" +
            "    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);\n" +
            "}\n" +
            "\n" +
            "vec3 hsv2rgb(vec3 c)\n" +
            "{\n" +
            "    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);\n" +
            "    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);\n" +
            "    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);\n" +
            "}\n" +
            "\n" +
            "float rgb2l(vec3 c)\n" +
            "{\n" +
            "    float lum = (0.212655 * c.r) + (0.715158 * c.g) + (0.072187 * c.b);\n" + // Photometric/digital luminance from ITU BT.709
            "    float plum = 0.0;\n" + // CIE perceived luminance (linear in shadows)
            "    if (lum <= (216.0/24389.0)) {\n" +
            "        plum = lum * (24389.0/27.0);\n" +
            "    } else {\n" +
            "        plum = pow(lum,(1.0/3.0)) * 116 - 16;\n" +
            "    }\n" +
            "    plum = plum / 100.0;\n" + // change scale  0..100 -> 0..1.0
//            "    plum = sqrt(0.299 * c.r * c.r + 0.587 * c.g * c.g + 0.114 * c.b * c.b);\n" + // HSP Color model
            "    return clamp(plum, 0.0, 1.0);\n" +
            "}\n" +
            "\n" +
            "float zoneBrightness(int zone)\n" +
            "{\n" +
            "    float b=0.0;\n" +
            "    b = float(pow(2.0, float(zone-1))) / 512.0;\n" + // light theory, each zone is twice as bright as the previous
            //            "    if (zone == 0) { b = 0.031; }\n" + // empirical values from: http://www.rags-int-inc.com/PhotoTechStuff/TonesnZones/
//            "    else if (zone == 1) { b = 0.044; }\n" +
//            "    else if (zone == 2) { b = 0.063; }\n" +
//            "    else if (zone == 3) { b = 0.088; }\n" +
//            "    else if (zone == 4) { b = 0.125; }\n" +
//            "    else if (zone == 5) { b = 0.177; }\n" +
//            "    else if (zone == 6) { b = 0.25; }\n" +
//            "    else if (zone == 7) { b = 0.354; }\n" +
//            "    else if (zone == 8) { b = 0.50; }\n" +
//            "    else if (zone == 9) { b = 0.707; }\n" +
//            "    else if (zone >= 10) { b = 1.0; }\n" +
//            "    else if (zone < 0) { b = 0.0; }\n" +
            "    return clamp(b, 0.0, 1.0);\n" +
            "}\n" +
            "\n" +
            "kernel vec4 BWZoneFilter(__sample image) {\n" +
            "float nzones = 11.0;\n" +
            "vec4 linear = srgb_to_linear(image);\n" +
            "vec3 ihsv = rgb2hsv(linear.rgb);\n" +
            "float iv  = rgb2l(linear.rgb);\n" + // convert RGB to luminosity
            "int zone = (int(iv * 110.0)+10) / 11;\n" +
            "float ov = 0.0;\n" +
            "ov = zoneBrightness(zone); \n" +
            "float left = float(zone)/nzones;\n" + // left boundary in input scale
            "float right = float(zone+1)/nzones;\n" + // right boundary in input scale
            "float rlum = zoneBrightness(zone+1);\n" + // right boundary in adjusted scale
            "float adj = (iv - left)/(right-left);\n" + // difference relative to lower zone boundary in input scale
            "adj = adj * (rlum - ov);\n" + // smooth out the value within the zone
            "ov = clamp(ov + adj, ov, rlum);\n" +
            //"ov = ov + adj*ov;\n" + // add adjustment from zone boundary
            "vec3 ohsv = vec3(ihsv.x, ihsv.x, ov);\n" +
            "vec3 orgb = hsv2rgb(ohsv);\n" +
            "vec4 result = vec4(orgb, 1.0);\n" +
            "return linear_to_srgb(result);\n" +
        "}"
    )

    // default settings
    override func setDefaults() {
        inputImage = nil
    }
    
    
    // filter display name
    func displayName() -> String {
        return "B&W Zone Filter"
    }
    
    
    // filter attributes
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: displayName(),
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage]
        ]
    }
    
 
    override func value(forKey key: String) -> Any? {
        switch key {
        case "inputImage":
            return inputImage
        case "outputImage":
            return outputImage
        default:
            log.error("Invalid key: \(key)")
            return nil
        }
    }

    override func setValue(_ value: Any?, forKey key: String) {
        switch key {
        case "inputImage":
            inputImage = value as? CIImage
        default:
            log.error("Invalid key: \(key)")
        }
    }

    override var outputImage: CIImage? {
        guard let inputImage = inputImage, let kernel = kernel else {
            log.error("No input image")
            return nil
        }
        
        // equalise the histogram (i.e. try to fix the exposure)
        let adjImg = inputImage
            .applyingFilter("CIPhotoEffectMono")
            .applyingFilter("YUCIHistogramEqualization")

        let extent = inputImage.extent
        let arguments = [adjImg] as [Any]
        
        return kernel.apply(extent: extent, arguments: arguments)
    }
}
