//
//  LinePath.swift
//  Clarity
//
//  Created by henry on 9/12/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

class LinePath: UIView {
    let path = UIBezierPath()
    let shapeLayer = CAShapeLayer()
    
    var startPoint: CGPoint = CGPoint(x: 0, y: 0) {
        didSet {
            drawPath()
        }
    }
    
    var endPoint: CGPoint = CGPoint(x: 0, y: 0) {
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
    
    var height: CGFloat = 10 {
        didSet {
            shapeLayer.lineWidth = height
        }
    }
    
    func drawPath() {
        path.removeAllPoints()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        shapeLayer.path = path.cgPath
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //layer.addSublayer(shapeLayer)
        shapeLayer.path = path.cgPath
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
