//
//  CustomMapView.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 4/9/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import Foundation
import MapKit

class CustomMapView: MKMapView {
    
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)!
        
        // Disable user interaction
        zoomEnabled = false
        scrollEnabled = false
        userInteractionEnabled = false
    }
    
    override func drawRect(rect: CGRect) {
        
        updateLayerProperties()
    }
    
    func updateLayerProperties() {
        
        layer.cornerRadius = frame.size.width / 2
        clipsToBounds = true
        layer.borderWidth = 8.0
        layer.borderColor = UIColor.whiteColor().CGColor
        
        if let superview = superview {
            
            superview.backgroundColor = UIColor.clearColor()
            superview.layer.shadowColor = UIColor.darkGrayColor().CGColor
            superview.layer.shadowOffset = CGSize(width: 3.0, height: 3.0)
            superview.layer.shadowRadius = 4.0
            superview.layer.shadowOpacity = 1.0
            superview.layer.masksToBounds = true
            superview.clipsToBounds = false
        }
    }
    
}