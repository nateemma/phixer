//
//  BlendMode.swift
//  phixer
//
//  Created by Philip Price on 09/27/19
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation


// enum describingthe available blend modes

enum BlendMode: Int, CustomStringConvertible {
    case additionCompositing = 0
    case color
    case colorBurn
    case colorDodge
    case darken
    case difference
    case divide
    case exclusion
    case hardLight
    case hue
    case lighten
    case linearBurn
    case linearDodge
    case luminosity
    case maximumCompositing
    case minimumCompositing
    case multiply
    case multiplyCompositing
    case overlay
    case pinLight
    case saturation
    case screen
    case softLight
    case sourceAtopCompositing
    case sourceInCompositing
    case sourceOutCompositing
    case sourceOverCompositing
    case subtract
    case count // the number of types. Be careful in switch statements...
    
    
    // function to get the CIFilter associated with the blend mode
    public func getFilter() -> CIFilter? {
        switch self {
        case .additionCompositing:
            return CIFilter(name: "CIAdditionCompositing")
        case .color:
            return CIFilter(name: "CIColorBlendMode")
        case .colorBurn:
            return CIFilter(name: "CIColorBurnBlendMode")
        case .colorDodge:
            return CIFilter(name: "CIColorDodgeBlendMode")
        case .darken:
            return CIFilter(name: "CIDarkenBlendMode")
        case .difference:
            return CIFilter(name: "CIDifferenceBlendMode")
        case .divide:
            return CIFilter(name: "CIDivideBlendMode")
        case .exclusion:
            return CIFilter(name: "CIExclusionBlendMode")
        case .hardLight:
            return CIFilter(name: "CIHardLightBlendMode")
        case .hue:
            return CIFilter(name: "CIHueBlendMode")
        case .lighten:
            return CIFilter(name: "CILightenBlendMode")
        case .linearBurn:
            return CIFilter(name: "CILinearBurnBlendMode")
        case .linearDodge:
            return CIFilter(name: "CILinearDodgeBlendMode")
        case .luminosity:
            return CIFilter(name: "CILuminosityBlendMode")
        case .maximumCompositing:
            return CIFilter(name: "CIMaximumCompositing")
        case .minimumCompositing:
            return CIFilter(name: "CIMinimumCompositing")
        case .multiply:
            return CIFilter(name: "CIMultiplyBlendMode")
        case .multiplyCompositing:
            return CIFilter(name: "CIMultiplyCompositing")
        case .overlay:
            return CIFilter(name: "CIOverlayBlendMode")
        case .pinLight:
            return CIFilter(name: "CIPinLightBlendMode")
        case .saturation:
            return CIFilter(name: "CISaturationBlendMode")
        case .screen:
            return CIFilter(name: "CIScreenBlendMode")
        case .softLight:
            return CIFilter(name: "CISoftLightBlendMode")
        case .sourceAtopCompositing:
            return CIFilter(name: "CISourceAtopCompositing")
        case .sourceInCompositing:
            return CIFilter(name: "CISourceInCompositing")
        case .sourceOutCompositing:
            return CIFilter(name: "CISourceOutCompositing")
        case .sourceOverCompositing:
            return CIFilter(name: "CISourceOverCompositing")
        case .subtract:
            return CIFilter(name: "CISubtractBlendMode")
        default:
            return nil
        }
    }
    

    // define the 'description' var which defines the corresponding (user-friendly) string for each value
    var description: String {
        return self.toString()
    }
    
    public func toString() -> String {
        switch self {
        case .additionCompositing:
            return "Addition Compositing"
        case .color:
            return "Color Blend"
        case .colorBurn:
            return "Color Burn Blend"
        case .colorDodge:
            return "Color Dodge Blend"
        case .darken:
            return "Darken Blend"
        case .difference:
            return "Difference Blend"
        case .divide:
            return "Divide Blend"
        case .exclusion:
            return "Exclusion Blend"
        case .hardLight:
            return "Hard Light Blend"
        case .hue:
            return "Hue Blend"
        case .lighten:
            return "Lighten Blend"
        case .linearBurn:
            return "Linear Burn Blend"
        case .linearDodge:
            return "Linear Dodge Blend"
        case .luminosity:
            return "Luminosity Blend"
        case .maximumCompositing:
            return "Maximum Compositing"
        case .minimumCompositing:
            return "Minimum Compositing"
        case .multiply:
            return "Multiply Blend"
        case .multiplyCompositing:
            return "Multiply Compositing"
        case .overlay:
            return "Overlay Blend"
        case .pinLight:
            return "Pin Light Blend"
        case .saturation:
            return "Saturation Blend"
        case .screen:
            return "Screen Blend"
        case .softLight:
            return "Soft Light Blend"
        case .sourceAtopCompositing:
            return "Source Atop Compositing"
        case .sourceInCompositing:
            return "Source In Compositing"
        case .sourceOutCompositing:
            return "Source Out Compositing"
        case .sourceOverCompositing:
            return "Source Over Compositing"
        case .subtract:
            return "Subtract Blend"
        default:
            return "UNKNOWN"
        }
    }
    
}
