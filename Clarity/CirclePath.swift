//
//  CirclePath.swift
//  Clarity
//
//  Created by Henry Ball on 6/3/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class CirclePath: UIView {

    let shapeLayer = CAShapeLayer()
    
    var value: Float = 0 {
        didSet {
            drawPath()
        }
    }
    
    var color: CGColor = UIColor.gray.cgColor {
        didSet {
            shapeLayer.strokeColor = color
        }
    }
    
    var width: CGFloat = 10 {
        didSet {
            shapeLayer.lineWidth = width
        }
    }
    
    func drawPath() {
        shapeLayer.strokeEnd = CGFloat(value)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(shapeLayer)
        let path = UIBezierPath(ovalIn: bounds)
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeEnd = CGFloat(value)
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.speed = 0.3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
