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


// Interface required of controlling View
protocol TitleViewDelegate: class {
    func backPressed()
}

class TitleView: UIView {

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
                backButton.isHidden = false
            } else {
                backButton.isHidden = true
            }
        }
    }
   
    
    
    // the title view components
    fileprivate var backButton:UIButton! = UIButton()
    fileprivate var titleLabel:UILabel! = UILabel()

    fileprivate let bannerHeight : CGFloat = 64.0
    fileprivate let buttonSize : CGFloat = 48.0
    fileprivate let statusBarOffset : CGFloat = 12.0

    convenience init() {
        self.init(frame: CGRect.zero)
        
        self.frame.size.height = bannerHeight * 0.75
        self.backgroundColor = UIColor.black
        
        self.addSubview(backButton)
        self.addSubview(titleLabel)
        
        //backButton.frame.size.height = self.frame.size.height - 8
        //backButton.frame.size.width = 2.0 * backButton.frame.size.height
        backButton.frame.size.height = self.frame.size.height - 8
        backButton.frame.size.width = backButton.frame.size.height
        backButton.setTitle("<", for: .normal)
        //backButton.backgroundColor = UIColor.flatBlack
        backButton.backgroundColor = UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:backButton.frame, andColors:[UIColor.black, UIColor.darkGray])
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 28.0)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        backButton.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        backButton.layer.cornerRadius = 5
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor.flatGray.cgColor

        titleLabel.frame.size.height = backButton.frame.size.height
        titleLabel.text = "        title        "
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        layout()
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)

    }
    
    private func layout(){
        titleLabel.frame.size.width = self.frame.size.width - backButton.frame.size.width // this can change, which is why it's here
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
    }
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        delegate?.backPressed()
    }
    
}
