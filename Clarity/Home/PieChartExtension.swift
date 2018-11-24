//
//  PieChartExtension.swift
//  Clarity
//
//  Created by henry on 10/16/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit

extension HomeViewController {
    
    func initPieChart() {
        let pathRect = CGRect(x: 0, y: 0, width: pieChart.bounds.width, height: pieChart.bounds.height)
        breakfastCircle = CirclePath(frame: pathRect)
        lunchCircle = CirclePath(frame: pathRect)
        dinnerCircle = CirclePath(frame: pathRect)
        snacksCircle = CirclePath(frame: pathRect)
        pieChartTrack = CirclePath(frame: pathRect)
        pieChartTrack.color = UIColor(red: 213/255, green: 213/255, blue: 213/255, alpha: 1.0).cgColor
        pieChartTrack.width = 5
        pieChartTrack.endAngle = 1.0
        pieChart.addSubview(pieChartTrack)
    }
    
    func updatePieChart(breakfast: Double, lunch: Double, dinner: Double, snacks: Double, dailyTotal : Double) {
        totalGallonsLabel.text = String(Int(dailyTotal))
        let breakfastPercentage = Float(breakfast/dailyTotal)
        drawSlice(slice: breakfastCircle, percentLabel: breakfastLegendPercent, percentage: breakfastPercentage, startAngle: 0.0, color: orange)
        let lunchPercentage = Float(lunch/dailyTotal)
        drawSlice(slice: lunchCircle, percentLabel: lunchLegendPercent, percentage: lunchPercentage, startAngle: breakfastPercentage, color: yellow)
        let dinnerPercentage = Float(dinner/dailyTotal)
        drawSlice(slice: dinnerCircle, percentLabel: dinnerLegendPercent, percentage: dinnerPercentage, startAngle: (breakfastPercentage+lunchPercentage), color: darkBlue)
        let snacksPercentage = Float(snacks/dailyTotal)
        drawSlice(slice: snacksCircle, percentLabel: snacksLegendPercent, percentage: snacksPercentage, startAngle: (breakfastPercentage+lunchPercentage+dinnerPercentage), color: blue)
    }
    
    func drawSlice(slice: CirclePath, percentLabel: UILabel, percentage: Float, startAngle: Float, color: UIColor) {
        slice.color = color.cgColor
        slice.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        slice.width = 10
        slice.startAngle = startAngle
        slice.endAngle = percentage + startAngle
        if (percentage.isNaN) {
            percentLabel.text = "0%"
        } else {
            percentLabel.text = String(Int(percentage*100)) + "%"
        }
        pieChart.addSubview(slice)
    }
}
