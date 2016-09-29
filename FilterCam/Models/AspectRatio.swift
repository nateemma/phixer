//
//  AspectRatio.swift
//  FilterCam
//
//  Created by Philip Price on 9/26/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
// enum type defining the different types of aspect ratio for the displayed/capture image

enum AspectRatio {
    case ratio_1_1
    case ratio_3_4
    case ratio_4_6
    case ratio_5_7
    case ratio_8_10
    case ratio_9_16
    case iphone_4
    case iphone_5
    case iphone_6
    case iphone_6_plus
    case iphone_7
    case iphone_7_plus
    case ipad
    case ipad_mini
    
    
    
    func getIconName() -> String{
        switch self {
        case .ratio_1_1:
            return "ic_aspect_1_1"
        case .ratio_3_4:
            return "ic_aspect_4_3"
            
        case .ratio_4_6:
            return "ic_aspect_4_6"
            
        case .ratio_5_7:
            return "ic_aspect_5_7"
            
        case .ratio_8_10:
            return "ic_aspect_8_10"
            
        case .ratio_9_16:
            return "ic_aspect_16:9"
            
        case .iphone_4:
            return "ic_aspect_iphone4"
            
        case .iphone_5:
            return "ic_aspect_iphone5"
            
        case .iphone_6:
            return "ic_aspect_iphone6"
            
        case .iphone_6_plus:
            return "ic_aspect_iphone6_plus"
            
        case .iphone_7:
            return "ic_aspect_iphone7"
            
        case .iphone_7_plus:
            return "ic_aspect_iphone7_plus"
            
        case .ipad:
            return "ic_aspect_ipad"
        case .ipad_mini:
            return "ic_aspect_ipad_mini"
        }
    }
    
    
    // Returns a tuple with the actual ratios as integers
    // Always ordered short:long sides
    func getRatio() -> (Int, Int){
        switch self {
        case .ratio_1_1:
            return (1,1)
        case .ratio_3_4:
            return (3,4)
            
        case .ratio_4_6:
            return (4,6)
            
        case .ratio_5_7:
            return (5,7)
            
        case .ratio_8_10:
            return (8,10)
            
        case .ratio_9_16:
            return (9,16)
            
        case .iphone_4:
            return (320,480)
            
        case .iphone_5:
            return (320, 568)
            
        case .iphone_6:
            return (375,667)
            
        case .iphone_7:
            return (375,667)
            
        case .iphone_6_plus:
            return (414,736)
            
        case .iphone_7_plus:
            return (414,736)
            
        case .ipad:
            return (1536,2048)
            
        case .ipad_mini:
            return (768,1024)
            
        }
    }
}
