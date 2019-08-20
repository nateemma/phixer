//
//  AVDepthData+Extensions.swift
//  phixer
//
//  Created by Philip Price on 8/13/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

//
//  Based on AVDepthData+Utils.swift, by Shuichi Tsutsumi on 2018/09/12.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import AVFoundation

extension AVDepthData {
    
    func convertToDepth() -> AVDepthData {
        let targetType: OSType
        switch depthDataType {
        case kCVPixelFormatType_DisparityFloat16:
            targetType = kCVPixelFormatType_DepthFloat16
        case kCVPixelFormatType_DisparityFloat32:
            targetType = kCVPixelFormatType_DepthFloat32
        default:
            return self
        }
        return converting(toDepthDataType: targetType)
    }
    
    func convertToDisparity() -> AVDepthData {
        let targetType: OSType
        switch depthDataType {
        case kCVPixelFormatType_DepthFloat16:
            targetType = kCVPixelFormatType_DisparityFloat16
        case kCVPixelFormatType_DepthFloat32:
            targetType = kCVPixelFormatType_DisparityFloat32
        default:
            return self
        }
        return converting(toDepthDataType: targetType)
    }
}
