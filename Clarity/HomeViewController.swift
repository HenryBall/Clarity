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
    @IBOutlet weak var scrollView: UIScrollView!
    
    var todaysTotal: Double!
    var dailyGoal : Double!
    var homeCircle : CirclePath!
    var homeTrack : CirclePath!
    var breakfastCircle : CirclePath!
    var lunchCircle : CirclePath!
    var dinnerCircle : CirclePath!
    var snacksCircle : CirclePath!
    var pieChartTrack : CirclePath!
    
    let today = Date()
    let databaseDateFormatter = DateFormatter()
    let labelDateFormatter = DateFormatter()
    
    var user: String!
    var userRef: DocumentReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        self.scrollView.delegate = self
        setUpDateFormatter()
        userRef = db.collection("users").document(defaults.string(forKey: "user_id")!)
        day = userRef.collection("meals").document(databaseDateFormatter.string(from: today))
        queryIngredientsFromFirebase()
        initCircle()
        initPieChart()
    }
    
    func setUpDateFormatter() {
        databaseDateFormatter.timeStyle = .none
        databaseDateFormatter.dateStyle = .long
        databaseDateFormatter.string(from: today)
        labelDateFormatter.timeStyle = .none
        labelDateFormatter.dateStyle = .long
        labelDateFormatter.dateFormat = "MMMM d"
        dateLabel.text = labelDateFormatter.string(from: today)
        self.navigationItem.title = labelDateFormatter.string(from: today)
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
        let pathRect = CGRect(x: 0, y: 0, width: circleView.bounds.width, height: circleView.bounds.height)
        homeCircle = CirclePath(frame: pathRect)
        homeCircle.width = 12
        homeCircle.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        homeCircle.roundedLineCap = true
        homeTrack = CirclePath(frame: pathRect)
        homeTrack.color = lightGrey.cgColor
        homeTrack.width = 5
        homeTrack.endAngle = 1.0
        circleView.addSubview(homeTrack)
        circleView.addSubview(homeCircle)
    }
    
    func updateCircle(dailyTotal: Float) {
        let percentage = dailyTotal/Float(dailyGoal)
        let percent = percentage * 100
        homeCircle.color = UIColor(red: CGFloat((187 - percent * 1.77)/255), green: CGFloat((218 - percent * 1.55)/255), blue: CGFloat((255 - percent * 1.3)/255), alpha: 1).cgColor
        percentLabel.text = String(describing: (Int(percent))) + "%"
        homeCircle.endAngle = percentage
    }
    
    func initPieChart() {
        let pathRect = CGRect(x: 0, y: 0, width: pieChart.bounds.width, height: pieChart.bounds.height)
        breakfastCircle = CirclePath(frame: pathRect)
        lunchCircle = CirclePath(frame: pathRect)
        dinnerCircle = CirclePath(frame: pathRect)
        snacksCircle = CirclePath(frame: pathRect)
        pieChartTrack = CirclePath(frame: pathRect)
        pieChartTrack.color = lightGrey.cgColor
        pieChartTrack.width = 5
        pieChartTrack.endAngle = 1.0
        pieChart.addSubview(pieChartTrack)
        setUpLegend()
    }
    
    func updatePieChart(breakfast: Double, lunch: Double, dinner: Double, snacks: Double, dailyTotal : Double) {
        
        let breakfastPercentage = Float(breakfast/dailyTotal)
        drawBreakfastPie(percentage: breakfastPercentage, startAngle: 0.0)
        
        let lunchPercentage = Float(lunch/dailyTotal)
        drawLunchPie(percentage: lunchPercentage, startAngle: breakfastPercentage)
        
        let dinnerPercentage = Float(dinner/dailyTotal)
        drawDinnerPie(percentage: dinnerPercentage, startAngle: (breakfastPercentage+lunchPercentage))
        
        let snacksPercentage = Float(snacks/dailyTotal)
        drawSnacksPie(percentage: snacksPercentage, startAngle: (breakfastPercentage+lunchPercentage+dinnerPercentage))
    }
    
    func drawBreakfastPie(percentage: Float, startAngle: Float) {
        breakfastCircle.color = UIColor(red: 89/255, green: 166/255, blue: 255/255, alpha: 255/255).cgColor
        breakfastCircle.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        breakfastCircle.width = 12
        breakfastCircle.startAngle = startAngle
        breakfastCircle.endAngle = percentage
        pieChart.addSubview(breakfastCircle)
    }
    
    func drawLunchPie(percentage: Float, startAngle: Float) {
        lunchCircle.color = UIColor(red: 255/255, green: 153/255, blue: 127/255, alpha: 255/255).cgColor
        lunchCircle.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        lunchCircle.width = 12
        lunchCircle.startAngle = startAngle
        lunchCircle.endAngle = startAngle + percentage
        pieChart.addSubview(lunchCircle)
    }
    
    func drawDinnerPie(percentage: Float, startAngle: Float) {
        dinnerCircle.color = UIColor(red: 155/255, green: 206/255, blue: 121/255, alpha: 255/255).cgColor
        dinnerCircle.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        dinnerCircle.width = 12
        dinnerCircle.startAngle = startAngle
        dinnerCircle.endAngle = startAngle + percentage
        pieChart.addSubview(dinnerCircle)
    }
    
    func drawSnacksPie(percentage: Float, startAngle: Float) {
        snacksCircle.color = UIColor(red: 239/255, green: 202/255, blue: 100/255, alpha: 255/255).cgColor
        snacksCircle.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        snacksCircle.width = 12
        snacksCircle.startAngle = startAngle
        snacksCircle.endAngle = startAngle + percentage
        pieChart.addSubview(snacksCircle)
    }
    
    func setUpLegend() {
        let legendRect = CGRect(x: 0, y: 0, width: breakfastLegend.bounds.width, height: breakfastLegend.bounds.height)
        setUpBreakfastLegend(legendRect: legendRect)
        setUpLunchLegend(legendRect: legendRect)
        setUpDinnerLegend(legendRect: legendRect)
        setUpSnacksLegend(legendRect: legendRect)
    }
    
    func setUpBreakfastLegend(legendRect: CGRect) {
        let breakfastLegendCircle = CirclePath(frame: legendRect)
        breakfastLegendCircle.fillColor = UIColor(red: 89/255, green: 166/255, blue: 255/255, alpha: 255/255).cgColor
        breakfastLegendCircle.endAngle = 1.0
        breakfastLegend.addSubview(breakfastLegendCircle)
    }
    
    func setUpLunchLegend(legendRect: CGRect) {
        let lunchLegendCircle = CirclePath(frame: legendRect)
        lunchLegendCircle.fillColor = UIColor(red: 255/255, green: 153/255, blue: 127/255, alpha: 255/255).cgColor
        lunchLegendCircle.endAngle = 1.0
        lunchLegend.addSubview(lunchLegendCircle)
    }
    
    func setUpDinnerLegend(legendRect: CGRect) {
        let dinnerLegendCircle = CirclePath(frame: legendRect)
        dinnerLegendCircle.fillColor = UIColor(red: 155/255, green: 206/255, blue: 121/255, alpha: 255/255).cgColor
        dinnerLegendCircle.endAngle = 1.0
        dinnerLegend.addSubview(dinnerLegendCircle)
    }
    
    func setUpSnacksLegend(legendRect: CGRect) {
        let snacksLegendCircle = CirclePath(frame: legendRect)
        snacksLegendCircle.fillColor = UIColor(red: 239/255, green: 202/255, blue: 100/255, alpha: 255/255).cgColor
        snacksLegendCircle.endAngle = 1.0
        snacksLegend.addSubview(snacksLegendCircle)
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
                let total = self.getTotalForDay(document: document!)
                let breakfastTotal = self.getBreakfastTotalForDay(document: document!)
                let lunchTotal = self.getLunchTotalForDay(document: document!)
                let dinnerTotal = self.getDinnerTotalForDay(document: document!)
                let snacksTotal = self.getSnackTotalForDay(document: document!)
                self.updateCircle(dailyTotal: Float(total))
                self.updatePieChart(breakfast: breakfastTotal, lunch: lunchTotal, dinner: dinnerTotal, snacks: snacksTotal, dailyTotal: total)
            }
        }
    }
    
    func getBreakfastTotalForDay(document: DocumentSnapshot) -> Double {
        if let breakfast_total = document.data()!["breakfast_total"]{
            var breakfastTotal = breakfast_total as! Double
            breakfastTotal.round()
            breakfastSubLabel.text = String(Int(breakfastTotal)) + " gallons of water consumed"
            return breakfastTotal
        } else {
            breakfastSubLabel.text = "No of water consumed"
            return 0.0
        }
    }
    
    func getLunchTotalForDay(document: DocumentSnapshot) -> Double {
        if let lunch_total = document.data()!["lunch_total"]{
            var lunchTotal = lunch_total as! Double
            lunchTotal.round()
            lunchSubLabel.text = String(Int(lunchTotal)) + " gallons of water consumed"
            return lunchTotal
        } else {
            lunchSubLabel.text = "No water consumed"
            return 0.0
        }
    }
    
    func getDinnerTotalForDay(document: DocumentSnapshot) -> Double {
        if let dinner_total = document.data()!["dinner_total"]{
            var dinnerTotal = dinner_total as! Double
            dinnerTotal.round()
            dinnerSubLabel.text = String(Int(dinnerTotal)) + " gallons of water consumed"
            return dinnerTotal
        } else {
            dinnerSubLabel.text = "No water consumed"
            return 0.0
        }
    }
    
    func getSnackTotalForDay(document: DocumentSnapshot) -> Double {
        if let snack_total = document.data()!["snacks_total"]{
            var snackTotal = snack_total as! Double
            snackTotal.round()
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
}


