//
//  StartupViewController.swift
//  This is the ViewController that is activated when the app is launched (after the launch screen)
//
//  Created by Philip Price on 10/23/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit

import simd


// This is the Main View Controller for phixer, really just here to allow background loading of data while animating the display

class StartupViewController: UIViewController, UINavigationControllerDelegate {
    
    var filterManager: FilterManager?
    
    @IBOutlet var uiView: UIView!
    
    @IBOutlet weak var iconImage: UIImageView!
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        /*** add this back when debugged
        // load filters etc. on a separate thread 
        DispatchQueue.main.async(execute: { () -> Void in
            self.filterManager = FilterManager.sharedInstance
        })
        ***/

        // set up a blank view the same size as the main view
        let blankView:UIImageView = UIImageView()
        blankView.frame = uiView.frame
        blankView.backgroundColor = UIColor.black
        blankView.image = blankView.image?.maskWithColor(color: .black)

        // create UIImages from the UIViews
        let startImage = CIImage(image: uiView.snapshot!)
        let endImage = CIImage(image: blankView.snapshot!)


        // set up the desired transition filter
        if let filter = CIFilter(name: "CIFlashTransition") {
            filter.setValue(2.0, forKey: "inputTime")
            filter.setValue(startImage, forKey: "inputImage")
            filter.setValue(endImage, forKey: "inputTargetImage")
            
            // run the filter
            log.debug("Starting transition using filter: \(filter.name)")
            iconImage.isHidden = true
            let image = UIImage(ciImage: filter.outputImage!)
            let iv:UIImageView = UIImageView()
            iv.image = image
            uiView.addSubview(iv)
            log.debug("...Ending transition")
            uiView = blankView
       } else {
            log.error("Could not create transition filter")
        }

        launchMainApp()
    }

    func launchMainApp(){

        UIApplication.topViewController()?.performSegue(withIdentifier: "MainMenu", sender: self)
       /***
         let vc = MainMenuController()
         UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
        ***/
    }
    
    
}


extension UIView {
    // create a UIImage from a view
    var snapshot: UIImage? {
        UIGraphicsBeginImageContext(self.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}

extension UIImage {
    
    func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!
        
        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        
        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
    
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
