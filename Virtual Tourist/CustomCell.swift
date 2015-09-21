//
//  CustomCell.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 4/9/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation
import UIKit


// Custom cell for MemeCollectionViewController
class CustomCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        contentMode = .Center
        backgroundColor = UIColor(red: 236.0/255, green: 240.0/255, blue: 241.0/255, alpha: 1.0)
        layer.cornerRadius = 4.0
    }
}