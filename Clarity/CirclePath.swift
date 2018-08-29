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
    
    var startAngle: Float = 0 {
        didSet {
            drawPath()
        }
    }
    
    var endAngle: Float = 0 {
        didSet {
            drawPath()
        }
    }
    
    var color: CGColor = UIColor.clear.cgColor {
        didSet {
            shapeLayer.strokeColor = color
        }
    }
    
    var fillColor: CGColor = UIColor.clear.cgColor {
        didSet {
            shapeLayer.fillColor = fillColor
        }
    }
    
    var roundedLineCap: Bool = false {
        didSet {
            if roundedLineCap {
                shapeLayer.lineCap = kCALineCapRound
            } else {
                shapeLayer.lineCap = kCALineCapSquare
            }
        }
    }
    
    var width: CGFloat = 10 {
        didSet {
            shapeLayer.lineWidth = width
        }
    }
    
    func drawPath() {
        shapeLayer.strokeStart = CGFloat(startAngle)
        shapeLayer.strokeEnd = CGFloat(endAngle)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.addSublayer(shapeLayer)
        let path = UIBezierPath(ovalIn: bounds)
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color
        shapeLayer.fillColor = fillColor
        shapeLayer.strokeStart = CGFloat(startAngle)
        shapeLayer.strokeEnd = CGFloat(endAngle)
        shapeLayer.speed = 0.3
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
