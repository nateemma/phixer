//
//  FilterGalleryViewController.swift
//  FilterCam
//
//  ViewController that provides a gallery view with previews of each filter, organised into Categories
//
//  Created by Philip Price on 10/31/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import GPUImage
import Neon


class FilterGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    
    private var bannerView: UIView! = UIView()
    fileprivate var galleryView: UICollectionView!
    fileprivate var galleryViewLayout = UICollectionViewFlowLayout()
    
    private var filterList: [String] = []
    
    private var isLandscape : Bool = false
    private var screenSize : CGRect = CGRect.zero
    private var displayWidth : CGFloat = 0.0
    private var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let statusBarOffset : CGFloat = 12.0

    private var itemsPerRow: CGFloat = 3
    private var cellSpacing: CGFloat = 2
    private var indicatorWidth: CGFloat = 41
    private var indicatorHeight: CGFloat = 8
    
    let leftOffset: CGFloat = 11
    let rightOffset: CGFloat = 7
    let height: CGFloat = 34
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 11.0, left: 10.0, bottom: 11.0, right: 10.0)
    
    
    fileprivate var currCategory: FilterManager.CategoryType = FilterManager.CategoryType.none
    fileprivate var filterManager:FilterManager = FilterManager.sharedInstance
    
    //let layout = UICollectionViewFlowLayout()
    
    
    ////////////////////////////////////////////
    // MARK: - View Lifecycle
    ////////////////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isLandscape = UIDevice.current.orientation.isLandscape
        displayHeight = view.height
        displayWidth = view.width

        initGalleryItems()
        
        layoutViews()
        
        galleryView.reloadData()
    }
    
    
    
    private func initGalleryItems() {
        galleryView = UICollectionView(frame: CGRect.zero, collectionViewLayout: galleryViewLayout)
        galleryView?.delegate   = self
        galleryView?.dataSource = self
        galleryView?.register(FilterGalleryViewCell2.self, forCellWithReuseIdentifier: FilterGalleryViewCell.reuseID)
        
        currCategory = filterManager.getCurrentCategory()
        filterList = filterManager.getFilterList(currCategory)!
    }
    
    
    
    private func layoutViews(){

        
        if (isLandscape){
            itemsPerRow = 4
        } else {
            itemsPerRow = 3
        }

        layoutBanner()
        view.addSubview(bannerView)
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: 8.0, otherSize: bannerView.frame.size.height)
        
        galleryView.frame.size.width = view.frame.size.width
        galleryView.frame.size.height = view.frame.size.height - bannerView.frame.size.height
        view.addSubview(galleryView)
        galleryView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: galleryView.frame.size.height)
    }
    
    
    func suspend(){
        let indexPath = galleryView.indexPathsForVisibleItems
        var i:Int = 0
        var cell: FilterGalleryViewCell2?
        for index in indexPath{
            cell = galleryView.cellForItem(at: index) as! FilterGalleryViewCell2?
            cell?.suspend()
        }
        //filterList = []
    }
    
    ////////////////////////////////////////////
    // MARK: - layout
    ////////////////////////////////////////////
    
    
    // Banner View (title)
    private var backButton:UIButton! = UIButton()
    private var titleLabel:UILabel! = UILabel()
    
    func layoutBanner(){

        bannerView.frame.size.height = bannerHeight * 0.75
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.black
        
        bannerView.addSubview(backButton)
        bannerView.addSubview(titleLabel)
        
        backButton.frame.size.height = bannerView.frame.size.height - 8
        backButton.frame.size.width = 2.0 * backButton.frame.size.height
        backButton.setTitle("< Back", for: .normal)
        backButton.backgroundColor = UIColor.flatMint()
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 20.0)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        
        titleLabel.frame.size.height = backButton.frame.size.height
        titleLabel.frame.size.width = view.width - backButton.frame.size.width
        titleLabel.text = "Filter Gallery"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }

    
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    func backDidPress(){
        log.verbose("Back pressed")
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            dismiss(animated: true, completion: nil)
            return
        }
    }

    
    
    ////////////////////////////////////////////
    // MARK: - UICollectionViewDataSource
    ////////////////////////////////////////////
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterList.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // dequeue the cell
        let cell = galleryView.dequeueReusableCell(withReuseIdentifier: FilterGalleryViewCell.reuseID, for: indexPath) as! FilterGalleryViewCell2
        
        // configure based on the index
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        //log.verbose("Index: \(index) (\(self.filterList[index]))")
        if ((index>=0) && (index<filterList.count)){
            let key = self.filterList[index]
            cell.configureCell(frame: cell.frame, key:key, render:true)
            
        } else {
            log.warning("Index out of range (\(index)/\(filterList.count))")
        }
        //cell.layoutIfNeeded()
        return cell
    }
 

    
    
    ////////////////////////////////////////////
    // MARK: - UICollectionViewDelegate
    ////////////////////////////////////////////
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard (galleryView.cellForItem(at: indexPath) as? FilterGalleryViewCell2) != nil else {
            log.error("NIL cell")
            return
        }
        
        //let index:Int = (indexPath as NSIndexPath).row
        let index:Int = (indexPath as NSIndexPath).item
        let descr:FilterDescriptorInterface? = (self.filterManager.getFilterDescriptor(key:self.filterList[index]))
        log.verbose("Selected filter: \((descr?.key)!)")
        
        // suspend all active rendering and launch viewer for this filter
        filterManager.setSelectedFilter(key: (descr?.key)!)
        suspend()
        self.present(FilterDetailsViewController(), animated: true, completion: nil)
    }
    
    
    
    ////////////////////////////////////////////
    // MARK: - UICollectionViewFlowLayout
    ////////////////////////////////////////////
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    

    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }

}
