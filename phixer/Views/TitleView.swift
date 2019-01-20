//
//  TitleView.swift
//  Simple View to display a title and provide a "back" button 
//
//  Created by Philip Price on 10/20/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import ChameleonFramework
import Neon

// Interface required of controlling View
protocol TitleViewDelegate: class {
    func backPressed()
    func helpPressed()
    func menuPressed()
}

class TitleView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    weak var delegate:TitleViewDelegate? = nil
    
    public var title:String = "title" {
        didSet {
            titleLabel.text = title
            layout()
        }
    }

    public var backButtonEnabled:Bool = true {
        didSet {
            if backButtonEnabled {
                backButton?.isHidden = false
            } else {
                backButton?.isHidden = true
            }
        }
    }
   
    
    
    // the title view components
    fileprivate var backButton:SquareButton? = nil
    fileprivate var helpButton:SquareButton? = nil
    fileprivate var menuButton:SquareButton? = nil
    fileprivate var titleLabel:UILabel! = UILabel()

    fileprivate let bannerHeight : CGFloat = 64.0
    fileprivate let buttonSize : CGFloat = 48.0
    fileprivate let statusBarOffset : CGFloat = 2.0

    
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        theme = ThemeManager.currentTheme()
        layout()
    }

    
    
    private func layout(){
        
        self.frame.size.height = bannerHeight * 0.75
        self.backgroundColor = theme.titleColor
        
        
        /***
        //backButton.frame.size.height = self.frame.size.height - 8
        //backButton.frame.size.width = 2.0 * backButton.frame.size.height
        backButton.frame.size.height = self.frame.size.height - 8
        backButton.frame.size.width = backButton.frame.size.height
        backButton.setTitle("<", for: .normal)
        //backButton.backgroundColor = UIColor.flatBlack
        backButton.backgroundColor = UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:backButton.frame, andColors:[theme.titleColor, theme.secondaryColor])
        backButton.setTitleColor(theme.titleTextColor, for: .normal)
        backButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 28.0)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        backButton.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        backButton.layer.cornerRadius = 5
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = theme.borderColor.cgColor
         ***/
        
        let side = self.frame.size.height - 8

        // set up the title label
        titleLabel.frame.size.height = self.frame.size.height
        titleLabel.frame.size.width = self.frame.size.width - (4.0 * side) - 16 // this can change, which is why it's here. 4 not 3 because we want to centre

        titleLabel.backgroundColor = theme.titleColor
        titleLabel.textColor = theme.titleTextColor
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        self.addSubview(titleLabel)

        
        // set up the buttons
        backButton = SquareButton(bsize: side)
        helpButton = SquareButton(bsize: side*0.65) // icon fills frame more than others, so reduce
        menuButton = SquareButton(bsize: side)
        
        backButton?.setImageAsset("ic_back")
        helpButton?.setImageAsset("ic_help")
        menuButton?.setImageAsset("ic_menu")
        
        for b in [backButton, helpButton, menuButton] {
            b?.backgroundColor = theme.titleColor.withAlphaComponent(0.8)
            b?.setTintable(true)
            b?.highlightOnSelection(true)
            self.addSubview(b!)
        }

        backButton?.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        helpButton?.addTarget(self, action: #selector(self.helpDidPress), for: .touchUpInside)
        menuButton?.addTarget(self, action: #selector(self.menuDidPress), for: .touchUpInside)

        
        backButton?.anchorToEdge(.left, padding: 2, width: (backButton?.frame.size.width)!, height: (backButton?.frame.size.height)!)
        menuButton?.anchorToEdge(.right, padding: 0, width: (menuButton?.frame.size.width)!, height: (menuButton?.frame.size.height)!)
        titleLabel.alignBetweenHorizontal(align: .toTheRightCentered, primaryView: backButton!, secondaryView: menuButton!, padding: 2, height: AutoHeight)
        helpButton?.align(.toTheLeftCentered, relativeTo: menuButton!, padding: 12, width: (helpButton?.frame.size.width)!, height: (helpButton?.frame.size.height)!)
        helpButton?.bringSubviewToFront(self)

    }
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        delegate?.backPressed()
    }
    
    @objc func helpDidPress(){
        log.verbose("Help pressed")
        delegate?.helpPressed()
    }
    
    @objc func menuDidPress(){
        log.verbose("Menu pressed")
        delegate?.menuPressed()
    }

}
