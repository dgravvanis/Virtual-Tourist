//
//  ShadeView.swift
//  Virtual Tourist
//
//  Created by Dimitrios Gravvanis on 17/9/15.
//  Copyright (c) 2015 dgravvanis. All rights reserved.
//

import UIKit

class ShadeView: UIView {
    
    override func layoutSubviews() {
        
        let b = frame.size.height / 2
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.BottomLeft, .TopLeft], cornerRadii: CGSizeMake(b, b)).CGPath
        
        
        let shadowLayer = CALayer()
        shadowLayer.shadowPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.BottomLeft, .TopLeft], cornerRadii: CGSizeMake(b, b)).CGPath
        shadowLayer.shadowOffset = CGSize(width: 3, height: 3)
        shadowLayer.shadowOpacity = 0.7
        shadowLayer.shadowRadius = 2
        shadowLayer.masksToBounds = false
        layer.insertSublayer(shadowLayer, atIndex: 0)
        
        let firstLayer = CALayer()
        firstLayer.frame = layer.bounds
        firstLayer.backgroundColor = UIColor(red: 52.0/255, green: 152.0/255, blue: 219.0/255, alpha: 1.0).CGColor
        firstLayer.mask = shapeLayer
        layer.insertSublayer(firstLayer, atIndex: 1)
        
    }
}
