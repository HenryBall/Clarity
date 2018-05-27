//
//  ViewController.swift
//  Clarity
//
//  Created by Robert on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import Charts

let defaults = UserDefaults.standard
let db = Firestore.firestore()
let storage = Storage.storage()
var ingredientsFromDatabase = [Ingredient]()

class HomeViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var barChart: BarChartView!
    @IBOutlet weak var dailyTotalLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var pieChart: PieChartView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    let shapeLayer = CAShapeLayer()
    
    let today = Date()
    let databaseDateFormatter = DateFormatter()
    let labelDateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        databaseDateFormatter.timeStyle = .none
        databaseDateFormatter.dateStyle = .long
        databaseDateFormatter.string(from: today)
        labelDateFormatter.timeStyle = .none
        labelDateFormatter.dateStyle = .long
        labelDateFormatter.dateFormat = "EEEE, MMM d"
        dateLabel.text = labelDateFormatter.string(from: today)
        
        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * 3, height:self.scrollView.frame.height)
        queryTotal()
        queryIngredientsFromFirebase()
        self.navigationController?.isNavigationBarHidden = true
        getBarGraphData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        queryTotal()
    }
    
//    func queryDailyGoal(){
//        let user = db.collection("users").document(defaults.string(forKey: "user_id")!)
//
//        user.getDocument { (document, error) in
//            if let document = document, document.exists {
//                if(document.data()?.keys.contains("water_goal"))!{
//                    self.dailyGoalLabel.text = String((Int(document.data()!["water_goal"] as! Double)))
//                }
//            } else {
//                print("Document does not exist")
//            }
//        }
//    }
 
    func updatePieChart(breakfast: Double, lunch: Double, dinner: Double, snacks: Double)  {
        
        let meals = [breakfast, lunch, dinner, snacks]
        let track = ["Breakfast", "Lunch", "Dinner", "Snacks"]
        var entries = [PieChartDataEntry]()
        for (index, value) in meals.enumerated() {
            let entry = PieChartDataEntry()
            entry.y = value
            entry.label = track[index]
            entries.append( entry)
        }
        
        // 3. chart setup
        let set = PieChartDataSet(values: entries, label: "")
        // this is custom extension method. Download the code for more details.

        set.colors = ChartColorTemplates.joyful()
     
        let data = PieChartData(dataSet: set)
        pieChart.data = data
        pieChart.chartDescription?.text = ""
        pieChart.noDataText = "No data available"
        pieChart.legend.horizontalAlignment = .right
        pieChart.legend.verticalAlignment = .center
        pieChart.legend.orientation = .vertical
        pieChart.legend.textColor = UIColor.white
        pieChart.drawEntryLabelsEnabled = false
        pieChart.isUserInteractionEnabled = false
        
        pieChart.holeRadiusPercent = 0.5
        pieChart.holeColor = UIColor.clear
        pieChart.transparentCircleColor = UIColor.clear
    }
    
    func getBarGraphData(){
        var waterData = [Double]()
        var breakfastTotal = 0.0
        var lunchTotal = 0.0
        var dinnerTotal = 0.0
        var snacksTotal = 0.0
        
        let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals")
        day.getDocuments { (querySnapshot, err) in
            if let err = err {
                print("error getting bar graph data")
            }else{
                for document in querySnapshot!.documents.reversed(){
                    if(waterData.count == 10){
                        return
                    }else{
                        if let breakfast_total = document.data()["breakfast_total"]{
                            breakfastTotal = breakfast_total as! Double
                        }
                        
                        if let lunch_total = document.data()["lunch_total"]{
                            lunchTotal = lunch_total as! Double
                        }
                        
                        if let dinner_total = document.data()["dinner_total"]{
                            dinnerTotal = dinner_total as! Double
                        }
                        
                        if let snacks_total = document.data()["snacks_total"]{
                            snacksTotal = snacks_total as! Double
                        }
                        
                        let total = breakfastTotal + lunchTotal + dinnerTotal + snacksTotal
                        waterData.append(total)
                    }
                }
                self.updateChartWithData(allWaterData: waterData.reversed())
            }
        }
    }
    
    func updateChartWithData(allWaterData: [Double]) {
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<allWaterData.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(allWaterData[i]))
            dataEntries.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "Gallons of water per day")
        let chartData = BarChartData(dataSet: chartDataSet)
        barChart.chartDescription?.text = ""
    
        barChart.xAxis.drawGridLinesEnabled = false
        barChart.rightAxis.drawGridLinesEnabled = false
        barChart.leftAxis.drawLabelsEnabled = false
        barChart.leftAxis.drawGridLinesEnabled = false
        barChart.noDataTextColor = UIColor.white
        barChart.xAxis.drawLabelsEnabled = false
        barChart.drawValueAboveBarEnabled = true
        barChart.data = chartData
    }
    
    @IBAction func breakfastTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.mealType = "breakfast"
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func lunchTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.mealType = "lunch"
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func dinnerTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.mealType = "dinner"
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func snacksTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.mealType = "snacks"
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func settingsBtnTapped(_ sender: Any) {
          let destination = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
          self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func queryIngredientsFromFirebase(){
        db.collection("water-footprint-data").getDocuments { (querySnapshot, err) in
            if let err = err {
                print(err)
            }else{
                for document in querySnapshot!.documents {
                    let name = document.documentID.uppercased()
                    let waterData = document.data()["gallons_water"] as! Double
                    let description = document.data()["description"] as! String
                    let servingSize = document.data()["average_weight_oz"] as! Double
                    let category = document.data()["category"] as! String
                    let current_ingredient = Ingredient(name: name, waterData: waterData, description: description, servingSize: servingSize, category: category)
                    ingredientsFromDatabase.append(current_ingredient)
                }
            }
        }
    }
    
    func queryTotal(){
        var breakfastTotal = 0.0
        var lunchTotal = 0.0
        var dinnerTotal = 0.0
        var snacksTotal = 0.0
        
        let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(databaseDateFormatter.string(from: today))
        
        day.getDocument { (document, error) in
            if(document?.exists)!{
                if let breakfast_total = document?.data()!["breakfast_total"]{
                    breakfastTotal = breakfast_total as! Double
                }
                
                if let lunch_total = document?.data()!["lunch_total"]{
                   lunchTotal = lunch_total as! Double
                }
                
                if let dinner_total = document?.data()!["dinner_total"]{
                    dinnerTotal = dinner_total as! Double
                }
                
                if let snacks_total = document?.data()!["snacks_total"]{
                    snacksTotal = snacks_total as! Double
                }

                let total = breakfastTotal + lunchTotal + dinnerTotal + snacksTotal
                self.dailyTotalLabel.text = String(Int(total))
                self.drawCircle(greenRating: CGFloat(total))
                self.updatePieChart(breakfast: breakfastTotal, lunch: lunchTotal, dinner: dinnerTotal, snacks: snacksTotal)
            }
        }
    }
    
    /* Circle Animation ************************************************************************************************/
    func drawCircle(greenRating: CGFloat) {
        // Green Rating is out of 360 to make the caculations for the circle right.
        let endAngle = CGFloat.pi / 2 + CGFloat.pi * (greenRating / 180)
        //Converting the Green Rating to a percentage out of 360 for the score label
        let percentage = Int(( greenRating / 360 ) * 100)
        percentLabel.text = String(describing: percentage) + "% of your daily total"
        //Tracklayer is the gray layer behind the animation color for the green rating
        // Code for the Rating Circle comes from: https://www.letsbuildthatapp.com/course_video?id=2342
        let trackLayer = CAShapeLayer()
        let center = circleView.center
        let circularPath = UIBezierPath(arcCenter: center, radius: 90, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        
        trackLayer.strokeColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 216/255).cgColor
        trackLayer.lineWidth = 20
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = kCALineCapRound
        view.layer.addSublayer(trackLayer)
        scrollView.layer.addSublayer(trackLayer)
        
        //ShapeLayer is the green layer used for the animation color for the green rating
        let motionPath = UIBezierPath(arcCenter: center, radius: 90, startAngle: CGFloat.pi / 2, endAngle: endAngle , clockwise: true)
        shapeLayer.path = motionPath.cgPath
        
        shapeLayer.strokeColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0).cgColor
        shapeLayer.lineWidth = 20
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.strokeEnd = 0
        
        //This will be the score we give the rating.
        view.layer.addSublayer(shapeLayer)
        scrollView.layer.addSublayer(shapeLayer)
        animateBar()
    }
    
    //Function to Animate the Green Rating. Code used from https://www.letsbuildthatapp.com/course_video?id=2342
    @objc private func animateBar() {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.toValue = 1
        basicAnimation.duration = 1
        basicAnimation.fillMode = kCAFillModeForwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView){
        // Test the offset and calculate the current page after scrolling ends
        let pageWidth:CGFloat = scrollView.frame.width
        let currentPage:CGFloat = floor((scrollView.contentOffset.x-pageWidth/2)/pageWidth)+1
        self.pageControl.currentPage = Int(currentPage) // Change the indicator
    }
}

