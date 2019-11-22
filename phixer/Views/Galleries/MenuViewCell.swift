//
//  MenuViewCell.swift
//  phixer
//
//  Created by Philip Price on 07/25/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit

// callback interfaces
protocol MenuViewCellDelegate: class {
    func itemSelected(key:String)
}


class MenuViewCell: UICollectionViewCell {
    
    var theme = ThemeManager.currentTheme()
    

    
    // delegate for handling events
    weak var delegate: MenuViewCellDelegate?

    
    public static let reuseID: String = "MenuViewCell"

    var cellIndex:Int = -1 // used for tracking cell reuse
    
    // display components
    var title : UILabel = UILabel()
    var subtitile : UILabel = UILabel()
    var imagePanel:UIView = UIView()
    var image : UIImageView = UIImageView()
    
    var menuItem: MenuItem? = nil

    
    let defaultWidth:CGFloat = UISettings.screenWidth
    let defaultHeight:CGFloat = UISettings.panelHeight
    

    fileprivate var initDone:Bool = false
    


    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        menuItem = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func doInit(){
        if (!initDone){
            initDone = true
            //loadInputs()
        }
    }
    
    
    
    private func doLayout(){
        
        if let menuItem = self.menuItem {
            doInit()
            
            //background
            self.backgroundColor = theme.titleColor
            
            // image
            imagePanel.frame.size.width = self.height
            imagePanel.frame.size.height = self.height
            imagePanel.backgroundColor = theme.titleColor.withAlphaComponent(0.9)
            
            image.frame.size.width = (self.height * 0.667).rounded()
            image.frame.size.height = image.frame.size.width
            //image.backgroundColor = theme.backgroundColor.withAlphaComponent(0.5)
            image.backgroundColor = theme.titleColor.withAlphaComponent(0.9)
            image.tintColor = theme.tintColor
            image.isHidden = false
            if menuItem.icon.isEmpty { // no icon, so check view
                if menuItem.view != nil {
                    image.image = menuItem.view
                } else {
                    image.isHidden = true
                    image.frame.size = CGSize.zero
                }
            } else {
                image.contentMode = .scaleAspectFit
                var icview: UIImage? = nil
                if menuItem.icon.contains("/") { // managed asset?
                    // can't tint managed assets, so just load
                    icview = ImageManager.getImageFromAssets(assetID: menuItem.icon, size: image.frame.size)
                    image.image = icview
                } else { // named icon
                    icview = UIImage(named: menuItem.icon)
                    if (icview == nil){
                        log.warning("icon not found: \(menuItem.icon)")
                        icview = UIImage(named:"ic_unknown")
                    }
                    let tintableImage = icview!.withRenderingMode(.alwaysTemplate)
                    image.image = tintableImage
               }
            }
            imagePanel.addSubview(image)
            image.anchorInCenter(width: image.frame.size.width, height: image.frame.size.height)
            
            // title
            title.textAlignment = .center
            title.textColor = theme.subtitleTextColor
            title.frame.size.width = self.width - self.height
            title.frame.size.height = (self.height * 0.3).rounded()
            title.backgroundColor = theme.titleColor.withAlphaComponent(0.9)
            title.font = theme.getFont(ofSize: 20.0, weight: UIFont.Weight.light)
            title.lineBreakMode = NSLineBreakMode.byWordWrapping
            title.numberOfLines = 0
            title.text = menuItem.title
            
            // subtitile
            subtitile.textAlignment = .center
            subtitile.textColor = theme.subtitleTextColor
            subtitile.frame.size.width = self.width - self.height
            subtitile.frame.size.height = (self.height - title.frame.size.height).rounded()
            subtitile.backgroundColor = theme.titleColor.withAlphaComponent(0.9)
            subtitile.font = theme.getFont(ofSize: 12.0, weight: UIFont.Weight.thin)
            subtitile.lineBreakMode = NSLineBreakMode.byWordWrapping
            subtitile.numberOfLines = 0
            if !menuItem.subtitile.isEmpty {
                subtitile.text = menuItem.subtitile
            } else {
                subtitile.isHidden = true
                subtitile.frame.size = CGSize.zero
                title.frame.size.height = (self.height).rounded()
           }
            
            // layout
            self.addSubview(imagePanel)
            self.addSubview(title)
            self.addSubview(subtitile)
            
            imagePanel.anchorAndFillEdge(.left, xPad: 0, yPad: 0, otherSize: imagePanel.frame.size.width)
            title.align(.toTheRightMatchingTop, relativeTo: imagePanel, padding: 0.0, width: title.frame.size.width, height: title.frame.size.height)
            subtitile.align(.underMatchingLeft, relativeTo: title, padding: 0.0, width: subtitile.frame.size.width, height: subtitile.frame.size.height)
        }
    }
    
    
    public func configureCell(frame: CGRect, index:Int, menuItem: MenuItem) {
        
        DispatchQueue.main.async(execute: { () -> Void in
            //log.debug("index:\(index), key:\(key)")
            self.cellIndex = index
            
            self.menuItem = menuItem
            
            self.doLayout()
        })
        
    }


    open func suspend(){
        //log.debug("Suspending cell: \((filterDescriptor?.key)!)")

        // release all filters
        //filterStrip.suspend()
    }
    
    
    /////////////////////
    // Touch Handlers
    /////////////////////
    

}


