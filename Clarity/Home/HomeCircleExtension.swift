//
//  HomeCircleExtension.swift
//  Clarity
//
//  Created by henry on 10/16/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

extension HomeViewController {
    
    func initCircle() {
        let pathRect = CGRect(x: 0, y: 0, width: circleView.bounds.width, height: circleView.bounds.height)
        homeCircle = CirclePath(frame: pathRect)
        homeCircle.width = 10
        homeCircle.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        homeCircle.roundedLineCap = true
        homeTrack = CirclePath(frame: pathRect)
        homeTrack.color = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        homeTrack.width = 4
        homeTrack.endAngle = 1.0
        circleView.addSubview(homeTrack)
        circleView.addSubview(homeCircle)
    }
    
    func updateCircle(circle: CirclePath, label: UILabel, total: Float, limit: Float) {
        let percentage = total/limit
        let percent = percentage * 100
        //homeCircle.color = UIColor(red: CGFloat((187 - percent * 1.77)/255), green: CGFloat((218 - percent * 1.55)/255), blue: CGFloat((255 - percent * 1.3)/255), alpha: 1).cgColor
        circle.color = blue.cgColor
        label.text = String(describing: (Int(percent))) + "%"
        circle.endAngle = percentage
    }
}
