//
//  EditBaseMenuInterface.swift
//  phixer
//
//  Created by Philip Price on 01/11/19
//  Copyright © 2019 Nateemma. All rights reserved.
//

// The interface that all EditBaseMenuClass instances must implement

protocol EditBaseMenuInterface: class {
    

    // returns the text to display at the top of the window
    func getTitle() -> String
    
    // returns the list of Adornments (text, icon/image, handler)
    func getItemList() -> [Adornment]

    // function to handle a selected item
    func handleSelection(key:String)
  
}

