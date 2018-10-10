//
//  CameraSpeed.swift
//  phixer
//
//  Created by Philip Price on 9/26/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import AVFoundation

// enum type defining the different shutter speed allowed
// The raw value of the enum is a (value,timescale) tuple that can be used to make a CMTime variable

enum CameraSpeed {
    
    case speed_auto
    case speed_1_1000
    case speed_1_800
    case speed_1_640
    case speed_1_500
    case speed_1_400
    case speed_1_320
    case speed_1_250
    case speed_1_200
    case speed_1_160
    case speed_1_125
    case speed_1_100
    case speed_1_80
    case speed_1_60
    case speed_1_50
    case speed_1_40
    case speed_1_30
    case speed_1_25
    case speed_1_20
    case speed_1_15
    case speed_1_13
    case speed_1_10
    case speed_1_8
    case speed_1_6
    case speed_1_5
    case speed_1_4
    case speed_1_3
    case speed_1_2
    case speed_1_1
    case speed_2_1
    case speed_3_1
    case speed_4_1
    case speed_5_1
    case speed_6_1
    case speed_8_1
    case speed_10_1
    case speed_13_1
    case speed_15_1
    case speed_20_1
    case speed_25_1
    case speed_30_1
    case speed_40_1


    // convert enum to String
    func getString() -> String{
        switch self {
        case .speed_auto:
            return "Auto"
        case .speed_1_1000:
            return "1/1000"
        case .speed_1_800:
            return "1/800"
        case .speed_1_640:
            return "1/640"
        case .speed_1_500:
            return "1/500"
        case .speed_1_400:
            return "1/400"
        case .speed_1_320:
            return "1/320"
        case .speed_1_250:
            return "1/250"
        case .speed_1_200:
            return "1/200"
        case .speed_1_160:
            return "1/160"
        case .speed_1_125:
            return "1/125"
        case .speed_1_100:
            return "1/100"
        case .speed_1_80:
            return "1/80"
        case .speed_1_60:
            return "1/60"
        case .speed_1_50:
            return "1/50"
        case .speed_1_40:
            return "1/40"
        case .speed_1_30:
            return "1/30"
        case .speed_1_25:
            return "1/25"
        case .speed_1_20:
            return "1/20"
        case .speed_1_15:
            return "1/15"
        case .speed_1_13:
            return "1/13"
        case .speed_1_10:
            return "1/10"
        case .speed_1_8:
            return "1/8"
        case .speed_1_6:
            return "1/6"
        case .speed_1_5:
            return "1/5"
        case .speed_1_4:
            return "1/4"
        case .speed_1_3:
            return "1/3"
        case .speed_1_2:
            return "1/2"
        case .speed_1_1:
            return "1"
        case .speed_2_1:
            return "2"
        case .speed_3_1:
            return "3"
        case .speed_4_1:
            return "4"
        case .speed_5_1:
            return "5"
        case .speed_6_1:
            return "6"
        case .speed_8_1:
            return "8"
        case .speed_10_1:
            return "10"
        case .speed_13_1:
            return "13"
        case .speed_15_1:
            return "15"
        case .speed_20_1:
            return "20"
        case .speed_25_1:
            return "25"
        case .speed_30_1:
            return "30"
        case .speed_40_1:
            return "40"
        }
    }
    
    
    // convert enum into a CMTime format so that it can be used with the AV interfaces
    func getSpeedAsTime()->CMTime {
        switch self{
        case .speed_auto :
            return CMTimeMake(0,0) // special case
        case .speed_1_1000:
            return CMTimeMake(1, 1000)
        case .speed_1_800:
            return CMTimeMake(1,800)
        case .speed_1_640:
            return CMTimeMake(1,640)
        case .speed_1_500:
            return CMTimeMake(1,500)
        case .speed_1_400:
            return CMTimeMake(1,400)
        case .speed_1_320:
            return CMTimeMake(1,320)
        case .speed_1_250:
            return CMTimeMake(1,250)
        case .speed_1_200:
            return CMTimeMake(1,200)
        case .speed_1_160:
            return CMTimeMake(1,160)
        case .speed_1_125:
            return CMTimeMake(1,125)
        case .speed_1_100:
            return CMTimeMake(1,100)
        case .speed_1_80:
            return CMTimeMake(1,80)
        case .speed_1_60:
            return CMTimeMake(1,60)
        case .speed_1_50:
            return CMTimeMake(1,50)
        case .speed_1_40:
            return CMTimeMake(1,40)
        case .speed_1_30:
            return CMTimeMake(1,30)
        case .speed_1_25:
            return CMTimeMake(1,25)
        case .speed_1_20:
            return CMTimeMake(1,20)
        case .speed_1_15:
            return CMTimeMake(1,15)
        case .speed_1_13:
            return CMTimeMake(1,13)
        case .speed_1_10:
            return CMTimeMake(1,10)
        case .speed_1_8:
            return CMTimeMake(1,8)
        case .speed_1_6:
            return CMTimeMake(1,6)
        case .speed_1_5:
            return CMTimeMake(1,5)
        case .speed_1_4:
            return CMTimeMake(1,4)
        case .speed_1_3:
            return CMTimeMake(1,3)
        case .speed_1_2:
            return CMTimeMake(1,2)
        case .speed_1_1 :
            return CMTimeMake(1,1)
        case .speed_2_1:
            return CMTimeMake(2,1)
        case .speed_3_1:
            return CMTimeMake(3,1)
        case .speed_4_1:
            return CMTimeMake(4,1)
        case .speed_5_1:
            return CMTimeMake(5,1)
        case .speed_6_1:
            return CMTimeMake(6,1)
        case .speed_8_1:
            return CMTimeMake(8,1)
        case .speed_10_1:
            return CMTimeMake(10,1)
        case .speed_13_1:
            return CMTimeMake(13,1)
        case .speed_15_1:
            return CMTimeMake(15,1)
        case .speed_20_1:
            return CMTimeMake(20,1)
        case .speed_25_1:
            return CMTimeMake(25,1)
        case .speed_30_1:
            return CMTimeMake(30,1)
        case .speed_40_1:
            return CMTimeMake(40, 1)
        }
        
    }
}
