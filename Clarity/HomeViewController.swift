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
var proteins = [Ingredient]()
var fruits = [Ingredient]()
var vegetables = [Ingredient]()
var dairy = [Ingredient]()
var drinks = [Ingredient]()
var other = [Ingredient]()

class HomeViewController: UIViewController, UIScrollViewDelegate {
    
    struct barChartEntry {
        var date: Date
        var value: Double
    }
    
    @IBOutlet weak var avgLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var dailyTotal: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var pieChart: PieChartView!
    @IBOutlet weak var barChart: BarChartView!
    @IBOutlet var barGraphDateLabels: [UILabel]!
    
    var todaysTotal: Double!
    var dailyGoal : Double!
    var cp : CirclePath!
    var track : CirclePath!
    var trackPath : CAShapeLayer!
    var motionPath : CAShapeLayer!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    let today = Date()
    let databaseDateFormatter = DateFormatter()
    let labelDateFormatter = DateFormatter()
    
    var user: String!
    var userRef: DocumentReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.scrollView.delegate = self
        user = defaults.string(forKey: "user_id")!
        userRef = db.collection("users").document(user)
        queryIngredientsFromFirebase()
        getBarGraphData()
        databaseDateFormatter.timeStyle = .none
        databaseDateFormatter.dateStyle = .long
        databaseDateFormatter.string(from: today)
        labelDateFormatter.timeStyle = .none
        labelDateFormatter.dateStyle = .long
        labelDateFormatter.dateFormat = "MMMM d"
        dateLabel.text = labelDateFormatter.string(from: today)
        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * 3, height: 260.0)
        self.navigationItem.title = labelDateFormatter.string(from: today)
        
        initCircle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let group = DispatchGroup()
        group.enter()
        userRef.getDocument { (doc, error) in
            if let doc = doc, doc.exists {
                self.dailyGoal = doc.data()!["water_goal"] as! Double
                group.leave()
            } else {
                // Display error screen
                print("Document does not exist")
            }
        }

        group.notify(queue: .main) {
            self.getTodaysTotal()
        }
    }
    
    func initCircle() {
        let trackRect = CGRect(x: 0, y: 0, width: circleView.bounds.width, height: circleView.bounds.height)
        let pathRect = CGRect(x: 0, y: 0, width: circleView.bounds.width, height: circleView.bounds.height)
        cp = CirclePath(frame: trackRect)
        cp.width = 12
        cp.color = UIColor(red: 89/255, green: 166/255, blue: 255/255, alpha: 255/255).cgColor
        cp.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        
        track = CirclePath(frame: pathRect)
        track.color = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 216/255).cgColor
        track.width = 5
        track.value = 1.0
        
        circleView.addSubview(track)
        circleView.addSubview(cp)
    }
    
    func updateCircle(dailyTotal: Float) {
        let percentage = dailyTotal/Float(dailyGoal)
        percentLabel.text = String(describing: (Int(percentage * 100))) + "%"
        cp.value = percentage
    }
    
    func updateChartWithData(allWaterData: [barChartEntry]) {
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<allWaterData.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(allWaterData[i].value))
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "Gallons of water per day")
        chartDataSet.drawValuesEnabled = false
        
        let colors = Array(repeating: UIColor.black, count: allWaterData.count)
        chartDataSet.colors = colors
        
        //let limitLine = ChartLimitLine(limit: dailyGoal, label: "") //show daily limit on graph
        //limitLine.lineColor = UIColor.white
        //limitLine.lineWidth = 1
        
        barChart.xAxis.drawGridLinesEnabled = false //hide vertical grid lines
        barChart.xAxis.drawLabelsEnabled = false //hide x axis label
        
        //barChart.rightAxis.addLimitLine(limitLine) //show daily limit line on graph
        barChart.rightAxis.drawGridLinesEnabled = false //hide vertical line on right side
        barChart.rightAxis.drawAxisLineEnabled = false //hide horizontal axis lines
        barChart.rightAxis.labelTextColor = UIColor.black
        
        barChart.leftAxis.drawLabelsEnabled = false //hide axis labels on left side
        barChart.leftAxis.drawGridLinesEnabled = false //hide horizontal axis lines
        barChart.leftAxis.drawAxisLineEnabled = false //hide vertical line on right side
        
        barChart.drawBordersEnabled = false //hide borders
        barChart.drawValueAboveBarEnabled = false
        barChart.xAxis.labelPosition = .bottom
        barChart.xAxis.axisLineColor = UIColor.clear
        
        barChart.noDataTextColor = UIColor.white //set color of "no data available" text
        barChart.chartDescription?.text = "" //hide description under the chart
        barChart.legend.enabled = false //hide legend
        barChart.isUserInteractionEnabled = false
        barChart.data = BarChartData(dataSet: chartDataSet)
    }
    
    //Pie Chart
    func updatePieChart(breakfast: Double, lunch: Double, dinner: Double, snacks: Double)  {
        
        let meals = [breakfast, lunch, dinner, snacks]
        let track = ["Breakfast", "Lunch", "Dinner", "Snacks"]
        var entries = [PieChartDataEntry]()

        for (index, value) in meals.enumerated() {
            let entry = PieChartDataEntry()
            entry.y = value
            entry.label = track[index]
            entries.append(entry)
        }
    
        
        let set = PieChartDataSet(values: entries, label: "")
        set.colors = [UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1), UIColor(red: 126/255, green: 211/255, blue: 33/255, alpha: 1), UIColor(red: 118/255, green: 96/255, blue: 180/255, alpha: 1), UIColor(red: 59/255, green: 128/255, blue: 208/255, alpha: 1)]
        set.drawValuesEnabled = true
        
        let data = PieChartData(dataSet: set)
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol =  "%"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        
        pieChart.data = data
        pieChart.chartDescription?.text = ""
        pieChart.noDataText = "No data available"
        pieChart.usePercentValuesEnabled = true
        pieChart.noDataTextColor = UIColor.white
        pieChart.legend.horizontalAlignment = .center
        pieChart.legend.formSize = 20.0
        pieChart.legend.textColor = UIColor.white
        pieChart.drawEntryLabelsEnabled = false
        pieChart.isUserInteractionEnabled = false
        
        pieChart.holeRadiusPercent = 0.35
        pieChart.holeColor = UIColor.clear
        pieChart.transparentCircleColor = UIColor.clear
    }
    
    /* IBActions ********************************************************************************************************/
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
    
    /* Queries ************************************************************************************************/
    
    ///Queries all of the ingredients from our database: water-footprint-data, adds them to array ingredientsFromDatabase (a global array used throughout the application)
    func queryIngredientsFromFirebase(){
        db.collection("water-footprint-data").getDocuments { (querySnapshot, err) in
            if let err = err {
                print(err)
            }else{
                for document in querySnapshot!.documents {
                    let current_ingredient = Ingredient(document: document)
                    ingredientsFromDatabase.append(current_ingredient)
                    
                    switch(current_ingredient.category){
                    case "protein":
                        proteins.append(current_ingredient)
                    case "fruit":
                        fruits.append(current_ingredient)
                    case "vegetable":
                        vegetables.append(current_ingredient)
                    case "dairy":
                        dairy.append(current_ingredient)
                    case "drinks":
                        drinks.append(current_ingredient)
                    case "other":
                        other.append(current_ingredient)
                    default:
                        print("some item not in a category has been entered")
                    }
                }
            }
        }
    }
    
//    func getTodaysTotal() {
//        let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(databaseDateFormatter.string(from: today))
//
//        firebaseHelper.getTotalForDay(day: day) { (total, error) in
//            if let error = error {
//                print (error)
//            } else {
//                let totalAsString = String(Int(total))
//                if (totalAsString != self.dailyTotalLabel.text) {
//                    self.updateCircle(dailyTotal: Float(total))
//                    self.dailyTotalLabel.text = totalAsString
//                }
//            }
//        }
//    }
    
    func getTodaysTotal(){
        let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(databaseDateFormatter.string(from: today))
        
        day.getDocument { (document, error) in
            if(document?.exists)!{
                let total = self.getTotalForDay(document: document!)
                let breakfastTotal = self.getBreakfastTotalForDay(document: document!)
                let lunchTotal = self.getLunchTotalForDay(document: document!)
                let dinnerTotal = self.getDinnerTotalForDay(document: document!)
                let snacksTotal = self.getSnackTotalForDay(document: document!)
                let totalAsString = String(Int(total))
                self.getAverage()
                self.updateCircle(dailyTotal: Float(total))
                self.dailyTotal.text = totalAsString
                self.updatePieChart(breakfast: breakfastTotal, lunch: lunchTotal, dinner: dinnerTotal, snacks: snacksTotal)            }
        }
    }
    
    func getBreakfastTotalForDay(document: DocumentSnapshot) -> Double {
        if let breakfast_total = document.data()!["breakfast_total"]{
            let breakfastTotal = breakfast_total as! Double
            return breakfastTotal
        } else {
            return 0.0
        }
    }
    
    func getLunchTotalForDay(document: DocumentSnapshot) -> Double {
        if let lunch_total = document.data()!["lunch_total"]{
            let lunchTotal = lunch_total as! Double
            return lunchTotal
        } else {
            return 0.0
        }
    }
    
    func getDinnerTotalForDay(document: DocumentSnapshot) -> Double {
        if let Dinner_total = document.data()!["dinner_total"]{
            let DinnerTotal = Dinner_total as! Double
            return DinnerTotal
        } else {
            return 0.0
        }
    }
    
    func getSnackTotalForDay(document: DocumentSnapshot) -> Double {
        if let Snack_total = document.data()!["snacks_total"]{
            let SnackTotal = Snack_total as! Double
            return SnackTotal
        } else {
            return 0.0
        }
    }
    
    func getTotalForDay(document: DocumentSnapshot) -> Double {
        let breakfastTotal = getBreakfastTotalForDay(document: document)
        let lunchTotal = getLunchTotalForDay(document: document)
        let dinnerTotal = getDinnerTotalForDay(document: document)
        let snacksTotal = getSnackTotalForDay(document: document)
        let total = breakfastTotal + lunchTotal + dinnerTotal + snacksTotal
        return total
    }
    
    func getAverage() {
        db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").limit(to: 10).getDocuments { (querySnapshot, err) in
            var days : Int = 0
            var total : Double = 0
            if let err = err {
                print(err)
            } else {
                for document in querySnapshot!.documents {
                    days = days + 1
                    total = total + (self.getTotalForDay(document: document))
                }
                self.avgLabel.text = String(Int(total)/days)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView){
        let pageWidth:CGFloat = scrollView.frame.width
        let currentPage:CGFloat = floor((scrollView.contentOffset.x-pageWidth/2)/pageWidth)+1
        if(currentPage == 2){
            dateLabel.text = "Past 10 Days"
        }else{
            dateLabel.text = labelDateFormatter.string(from: today)
        }
        self.pageControl.currentPage = Int(currentPage)
    }
    
    func getBarGraphData(){
        var waterData = [Double]()
        var entries = [barChartEntry]()
        var dates = [Date]()
        
        let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").limit(to: 10)
        day.getDocuments { (querySnapshot, err) in
            if err != nil {
                print("Error getting bar graph data")
            }else{
                for document in querySnapshot!.documents.reversed(){
                    var breakfastTotal = 0.0, lunchTotal = 0.0, dinnerTotal = 0.0, snacksTotal = 0.0
                    
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
                
                    //Get dates to display under bar graph
                    print(document.documentID)
                    let dateStr = document.documentID
                    let oldFormatterr = DateFormatter()
                    oldFormatterr.dateStyle = .long
                    let date = oldFormatterr.date(from: dateStr)
                    dates.append(date!)
                    let sorted = dates.map{(($0 < Date() ? 1 : 0), $0)}.sorted(by:<).map{$1}
                    let newFormatter = DateFormatter()
                    newFormatter.dateFormat = "MM/dd"
                    
                    for i in 0 ... sorted.count-1 {
                        let dateString = newFormatter.string(from: sorted[i])
                        self.barGraphDateLabels[i].text = dateString
                    }
                    
                    let current = barChartEntry(date: date!, value: total)
                    entries.append(current)
                    entries.sort(by: { $0.date < $1.date })
                    
                    self.updateChartWithData(allWaterData: entries)
                    }
                
                
                if (waterData.count < 10) {
                    for _ in 1...(10 - waterData.count) {
                        waterData.append(0.0)
                    }
                }
            }
        }
    }
}


