//
//  ViewController.swift
//  Clarity
//
//  Created by Robert on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

//import UIKit
import Firebase
import GoogleSignIn
import Charts

let defaults = UserDefaults.standard
let db = Firestore.firestore()
let storage = Storage.storage()
var day : DocumentReference!
let lightGrey = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
let textColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
let mainBlue = UIColor(red: 89/255, green: 166/255, blue: 255/255, alpha: 1)
let lightestBlue = UIColor(red: 187/255, green: 218/255, blue: 255/255, alpha: 1)
let darkerBlue = UIColor(red: 39/255, green: 106/255, blue: 184/255, alpha: 1)
let darkestBlue = UIColor(red: 10/255, green: 63/255, blue: 125/255, alpha: 1)
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
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet var barGraphDateLabels: [UILabel]!
    @IBOutlet weak var breakfastSubLabel: UILabel!
    @IBOutlet weak var lunchSubLabel: UILabel!
    @IBOutlet weak var dinnerSubLabel: UILabel!
    @IBOutlet weak var snacksSubLabel: UILabel!
    @IBOutlet weak var breakfastLegend: UIView!
    @IBOutlet weak var lunchLegend: UIView!
    @IBOutlet weak var dinnerLegend: UIView!
    @IBOutlet weak var snacksLegend: UIView!
    
    var todaysTotal: Double!
    var dailyGoal : Double!
    var cp : CirclePath!
    var track : CirclePath!
    var breakfastCP : CirclePath!
    var lunchCP : CirclePath!
    var dinnerCP : CirclePath!
    var snacksCP : CirclePath!
    var pieChartTrack : CirclePath!
    
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
        databaseDateFormatter.timeStyle = .none
        databaseDateFormatter.dateStyle = .long
        databaseDateFormatter.string(from: today)
        labelDateFormatter.timeStyle = .none
        labelDateFormatter.dateStyle = .long
        labelDateFormatter.dateFormat = "MMMM d"
        user = defaults.string(forKey: "user_id")!
        userRef = db.collection("users").document(user)
        day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(databaseDateFormatter.string(from: today))
        queryIngredientsFromFirebase()
        dateLabel.text = labelDateFormatter.string(from: today)
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
        cp.color = mainBlue.cgColor
        cp.color = UIColor(red: 89/255, green: 166/255, blue: 255/255, alpha: 255/255).cgColor
        cp.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        cp.roundedLineCap = true
        
        track = CirclePath(frame: pathRect)
        track.color = lightGrey.cgColor
        track.width = 5
        track.endAngle = 1.0
        
        circleView.addSubview(track)
        circleView.addSubview(cp)
    }
    
    func updateCircle(dailyTotal: Float) {
        let percentage = dailyTotal/Float(dailyGoal)
        let percent = percentage * 100
        cp.color = UIColor(red: CGFloat((187 - percent * 1.77)/255), green: CGFloat((218 - percent * 1.55)/255), blue: CGFloat((255 - percent * 1.3)/255), alpha: 1).cgColor
        percentLabel.text = String(describing: (Int(percent))) + "%"
        cp.endAngle = percentage
    }
    
    func drawPieChart(breakfast: Double, lunch: Double, dinner: Double, snacks: Double, dailyTotal : Double) {
        let pathRect = CGRect(x: 0, y: 0, width: pieChart.bounds.width, height: pieChart.bounds.height)
        let legendRect = CGRect(x: 0, y: 0, width: breakfastLegend.bounds.width, height: breakfastLegend.bounds.height)
        
        let breakfastLegendCP = CirclePath(frame: legendRect)
        breakfastLegendCP.fillColor = UIColor(red: 89/255, green: 166/255, blue: 255/255, alpha: 255/255).cgColor
        breakfastLegendCP.endAngle = 1.0
        breakfastLegendCP.width = 10
        breakfastLegend.addSubview(breakfastLegendCP)
        
        let lunchLegendCP = CirclePath(frame: legendRect)
        lunchLegendCP.fillColor = UIColor(red: 255/255, green: 153/255, blue: 127/255, alpha: 255/255).cgColor
        lunchLegendCP.endAngle = 1.0
        lunchLegendCP.width = 10
        lunchLegend.addSubview(lunchLegendCP)
        
        let dinnerLegendCP = CirclePath(frame: legendRect)
        dinnerLegendCP.fillColor = UIColor(red: 155/255, green: 206/255, blue: 121/255, alpha: 255/255).cgColor
        dinnerLegendCP.endAngle = 1.0
        dinnerLegendCP.width = 10
        dinnerLegend.addSubview(dinnerLegendCP)
        
        let snacksLegendCP = CirclePath(frame: legendRect)
        snacksLegendCP.fillColor = UIColor(red: 239/255, green: 202/255, blue: 100/255, alpha: 255/255).cgColor
        snacksLegendCP.endAngle = 1.0
        snacksLegendCP.width = 10
        snacksLegend.addSubview(snacksLegendCP)
        
        pieChartTrack = CirclePath(frame: pathRect)
        pieChartTrack.color = lightGrey.cgColor
        pieChartTrack.width = 5
        pieChartTrack.endAngle = 1.0
        
        let breakfastPercentage = Float(breakfast)/Float(dailyTotal)
        breakfastCP = CirclePath(frame: pathRect)
        breakfastCP.color = UIColor(red: 89/255, green: 166/255, blue: 255/255, alpha: 255/255).cgColor
        breakfastCP.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        breakfastCP.width = 12
        breakfastCP.endAngle = breakfastPercentage
        
        let lunchPercentage = Float(lunch)/Float(dailyTotal)
        lunchCP = CirclePath(frame: pathRect)
        lunchCP.width = 12
        lunchCP.color = UIColor(red: 255/255, green: 153/255, blue: 127/255, alpha: 255/255).cgColor
        lunchCP.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        lunchCP.startAngle = breakfastCP.endAngle
        lunchCP.endAngle = breakfastCP.endAngle + lunchPercentage
        
        let dinnerPercentage = Float(dinner)/Float(dailyTotal)
        dinnerCP = CirclePath(frame: pathRect)
        dinnerCP.width = 12
        dinnerCP.color = UIColor(red: 155/255, green: 206/255, blue: 121/255, alpha: 255/255).cgColor
        dinnerCP.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        dinnerCP.startAngle = lunchCP.endAngle
        dinnerCP.endAngle = lunchCP.endAngle + dinnerPercentage
        
        let snacksPercentage = Float(snacks)/Float(dailyTotal)
        snacksCP = CirclePath(frame: pathRect)
        snacksCP.width = 12
        snacksCP.color = UIColor(red: 239/255, green: 202/255, blue: 100/255, alpha: 255/255).cgColor
        snacksCP.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        snacksCP.startAngle = dinnerCP.endAngle
        snacksCP.endAngle = dinnerCP.endAngle + snacksPercentage
        
        pieChart.addSubview(pieChartTrack)
        pieChart.addSubview(breakfastCP)
        pieChart.addSubview(lunchCP)
        pieChart.addSubview(dinnerCP)
        pieChart.addSubview(snacksCP)
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
    
    func getTodaysTotal(){
        day.getDocument { (document, error) in
            if(document?.exists)!{
                let total = floor(self.getTotalForDay(document: document!))
                let breakfastTotal = floor(self.getBreakfastTotalForDay(document: document!))
                let lunchTotal = floor(self.getLunchTotalForDay(document: document!))
                let dinnerTotal = floor(self.getDinnerTotalForDay(document: document!))
                let snacksTotal = floor(self.getSnackTotalForDay(document: document!))
                self.updateCircle(dailyTotal: Float(total))
                self.drawPieChart(breakfast: breakfastTotal, lunch: lunchTotal, dinner: dinnerTotal, snacks: snacksTotal, dailyTotal: total)
            }
        }
    }
    
    func getBreakfastTotalForDay(document: DocumentSnapshot) -> Double {
        if let breakfast_total = document.data()!["breakfast_total"]{
            let breakfastTotal = floor(breakfast_total as! Double)
            breakfastSubLabel.text = String(Int(breakfastTotal)) + " gallons of water consumed"
            return breakfastTotal
        } else {
            breakfastSubLabel.text = "No of water consumed"
            return 0.0
        }
    }
    
    func getLunchTotalForDay(document: DocumentSnapshot) -> Double {
        if let lunch_total = document.data()!["lunch_total"]{
            let lunchTotal = floor(lunch_total as! Double)
            lunchSubLabel.text = String(Int(lunchTotal)) + " gallons of water consumed"
            return lunchTotal
        } else {
            lunchSubLabel.text = "No water consumed"
            return 0.0
        }
    }
    
    func getDinnerTotalForDay(document: DocumentSnapshot) -> Double {
        if let dinner_total = document.data()!["dinner_total"]{
            let dinnerTotal = floor(dinner_total as! Double)
            dinnerSubLabel.text = String(Int(dinnerTotal)) + " gallons of water consumed"
            return dinnerTotal
        } else {
            dinnerSubLabel.text = "No water consumed"
            return 0.0
        }
    }
    
    func getSnackTotalForDay(document: DocumentSnapshot) -> Double {
        if let snack_total = document.data()!["snacks_total"]{
            let snackTotal = floor(snack_total as! Double)
            snacksSubLabel.text = String(Int(snackTotal)) + " gallons of water consumed"
            return snackTotal
        } else {
            snacksSubLabel.text = "No water consumed"
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
        let waterData = [Double]()
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
                }
                
                if (entries.count < 10) {
                    let oldFormatterr = DateFormatter()
                    oldFormatterr.dateStyle = .long
                    let date = oldFormatterr.date(from: "March 19, 2018")
                    for _ in 1...(10 - waterData.count) {
                        entries.append (barChartEntry(date: date!, value: 0))
                    }
                }
            }
        }
    }
}


