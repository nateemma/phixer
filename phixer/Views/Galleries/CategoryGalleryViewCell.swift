//
//  CategoryGalleryViewCell.swift
//  phixer
//
//  Created by Philip Price on 07/25/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
//import Kingfisher
import CoreImage

// callback interfaces
protocol CategoryGalleryViewCellDelegate: class {
    func categorySelected(category:String)
    func filterSelected(category:String, key:String)
}


class CategoryGalleryViewCell: UICollectionViewCell {
    
    var theme = ThemeManager.currentTheme()
    

    
    // delegate for handling events
    weak var delegate: CategoryGalleryViewCellDelegate?

    
    public static let reuseID: String = "CategoryGalleryViewCell"
    private static let filterManager = FilterManager.sharedInstance

    var cellIndex:Int = -1 // used for tracking cell reuse
    
    // display components
    var title : UILabel = UILabel()

    //var filterStrip: FilterSwipeView = FilterSwipeView()
    var filterStrip: SimpleSwipeView = SimpleSwipeView() // TEMP until FilterSwipeView is done

    
    var currCategory:String = ""
    
    let defaultWidth:CGFloat = UISettings.screenWidth
    let defaultHeight:CGFloat = UISettings.panelHeight
    

    fileprivate var initDone:Bool = false
    


    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        
        doInit()
        //background
        self.backgroundColor = theme.backgroundColor
        self.layer.cornerRadius = 2.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = theme.borderColor.withAlphaComponent(0.5).cgColor
        self.clipsToBounds = true
        
        // title
        title.textAlignment = .left
        title.textColor = theme.subtitleTextColor
        title.frame.size.width = self.width
        title.frame.size.height = (self.height * 0.3).rounded()
        title.backgroundColor = theme.subtitleColor.withAlphaComponent(0.9)
        title.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin)
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.numberOfLines = 0
        
        // scrolling strip of filtered images
        filterStrip.frame.size.height = self.height - title.frame.size.height - 4.0
        filterStrip.frame.size.width = self.width
        filterStrip.backgroundColor = theme.backgroundColor
        filterStrip.disableWrap()
        filterStrip.delegate = self
        
        
        // layout
        self.addSubview(title)
        self.addSubview(filterStrip)

        title.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: title.frame.height)
        filterStrip.align(.underCentered, relativeTo: title, padding: 4.0, width: filterStrip.frame.size.width, height: filterStrip.frame.size.height)

    }
    
    
    public func configureCell(frame: CGRect, index:Int, category:String) {
        
        DispatchQueue.main.async(execute: { () -> Void in
            //log.debug("index:\(index), key:\(key)")
            self.cellIndex = index
    
            self.currCategory = category
            
            self.title.text = CategoryGalleryViewCell.filterManager.getCategoryTitle(key: category)
            
            //TODO: update to use FilterSwipeView when ready
            let filters = CategoryGalleryViewCell.filterManager.getFilterList(category)
            var itemList: [Adornment] = []
            
            
            if (filters?.count)! > 0 {
                for f in filters! {
                    itemList.append(Adornment(key: f, text: f, icon: "", view: nil, isHidden: false))
                }
                //log.verbose("Category: \(category) Filters: \(filters)")
                self.filterStrip.setItems(itemList)
                self.filterStrip.isHidden = false
            } else {
                log.warning("No filters found for category: \(category)")
                self.filterStrip.isHidden = true
            }
        })
        
        self.doLayout()
        
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



//////////////////////////////////////////
// MARK: - Delegate functions
//////////////////////////////////////////

extension CategoryGalleryViewCell: AdornmentDelegate {
    func adornmentItemSelected(key: String) {
        if !key.isEmpty {
            DispatchQueue.main.async(execute: { () -> Void  in
                self.delegate?.filterSelected(category: self.currCategory, key: key)
            })
        }
    }
}
