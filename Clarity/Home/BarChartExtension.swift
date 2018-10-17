//
//  BarChartExtension.swift
//  Clarity
//
//  Created by henry on 10/16/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import Foundation
import UIKit

extension HomeViewController {
    
    /* func drawLine(view: UIView, line: LinePath, cur: Float, max: Float, color: UIColor, width: Int, animate: Bool) {
        line.color = color.cgColor
        line.height = view.frame.height
        line.roundedLineCap = true
        line.height = CGFloat(width)
        let percentToFill = CGFloat(cur/max)
        line.endPoint = CGPoint(x: view.bounds.maxX*percentToFill, y: view.bounds.midY)
        view.layer.addSublayer(line.shapeLayer)
        if (animate) {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.duration = 0.5
            line.shapeLayer.add(animation, forKey: "MyAnimation")
        }
    }
    
    func initBarChart() {
        let pathRect = CGRect(x: 0, y: 0, width: barOne.bounds.width, height: barOne.bounds.height)
        barOnePath = LinePath(frame: pathRect)
        barTwoPath = LinePath(frame: pathRect)
        barThreePath = LinePath(frame: pathRect)
    }
    
    func updateBarChartData(total: Int) {
        var map = [String : Any]()
        var barChartData = [[String : Any]]()
        let today = self.dayDateFormatter.string(from: self.today)
        userRef.getDocument { (doc, error) in
            if let doc = doc, doc.exists {
                let data = doc.get("barChartData")
                if (data != nil) {
                    barChartData = self.orderByIndex(data: (data as! [[String : Any]]))
                    if (barChartData.count == 5) {
                        barChartData = self.update(data: barChartData, total: total, removeLast: true)
                    } else {
                        barChartData = self.update(data: barChartData, total: total, removeLast: false)
                    }
                    self.userRef.setData(["barChartData" : barChartData], options: SetOptions.merge())
                } else {
                    map = ["index": 0, "date": today, "total": total]
                    barChartData.insert(map, at: 0)
                    self.userRef.setData(["barChartData" : barChartData], options: SetOptions.merge())
                }
                self.drawBars(data: barChartData)
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func update(data: [[String : Any]], total: Int, removeLast: Bool) ->  [[String : Any]] {
        var modifiedData = data
        var map = [String : Any]()
        let today = self.dayDateFormatter.string(from: self.today)
        if (today == (modifiedData[0]["date"] as! String)) {
            modifiedData[0]["total"] = total
        } else {
            map = ["index": 0, "date": today, "total": total]
            if removeLast { modifiedData.remove(at: 4) }
            for i in 0...data.count-1 { modifiedData[i]["index"] = (modifiedData[i]["index"] as! Int) + 1 }
            modifiedData.insert(map, at: 0)
        }
        return modifiedData
    }
    
    func drawBars(data: [[String : Any]]) {
        let color = UIColor(red: 89/255, green: 166/255, blue: 255/255, alpha: 255/255)
        let arrayOfViews = [barOne, barTwo, barThree]
        let arrayOfLines = [barOnePath, barTwoPath, barThreePath]
        let arrayOfLabels = [dateOne, dateTwo, dateThree]
        print(data)
        print(data.count-1)
        if (data.count <= arrayOfViews.count) {
            for i in 0...data.count - 1 {
                drawBar(view: arrayOfViews[i]!, line: arrayOfLines[i]!, date: arrayOfLabels[i]!, data: data[i], color: color)
            }
        } else {
            print("Avoviding an index out of bounds error")
        }
    }
    
    func drawBar(view: UIView, line: LinePath, date: UILabel, data: [String : Any], color: UIColor) {
        line.color = color.cgColor
        line.height = view.frame.height
        line.roundedLineCap = true
        date.text = data["date"] as? String
        date.backgroundColor = UIColor.white
        let total = Double(data["total"] as! Int)
        let percentToFill = CGFloat(total/dailyGoal)
        date.backgroundColor = UIColor.red
        line.startPoint = CGPoint(x: view.frame.minX, y: view.frame.minY - view.frame.height/2)
        line.endPoint = CGPoint(x: view.frame.maxX*percentToFill, y: view.frame.minY - view.frame.height/2)
        view.layer.addSublayer(line.shapeLayer)
    }
    
    func orderByIndex(data: [[String : Any]]) -> [[String : Any]] {
        let orderedData = data.sorted(by: { ($0["index"] as! Int) < ($1["index"] as! Int) })
        return orderedData
    } */
}
