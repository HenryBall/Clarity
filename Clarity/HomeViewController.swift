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
import Foundation
import CoreGraphics

let defaults                 = UserDefaults.standard
let db                       = Firestore.firestore()
let storage                  = Storage.storage()
var day                      : DocumentReference!
let orange                   = UIColor(red: 246/255, green: 121/255, blue: 79/255, alpha: 1)
let periwinkle               = UIColor(red: 153/255, green: 192/255, blue: 243/255, alpha: 1)
let blue                     = UIColor(red: 154/255, green: 225/255, blue: 241/255, alpha: 1)
let yellow                   = UIColor(red: 255/255, green: 215/255, blue: 130/255, alpha: 1)
var ingredientsFromDatabase  = [Ingredient]()
var proteins                 = [Ingredient]()
var fruits                   = [Ingredient]()
var vegetables               = [Ingredient]()
var dairy                    = [Ingredient]()
var drinks                   = [Ingredient]()
var other                    = [Ingredient]()
var recent                   = [[String: Any]]()

class HomeViewController: UIViewController, UIScrollViewDelegate {
    
    //UILabel
    @IBOutlet weak var dateLabel                : UILabel!
    @IBOutlet weak var percentLabel             : UILabel!
    @IBOutlet weak var limitLabel               : UILabel!
    @IBOutlet weak var averageLabel             : UILabel!
    @IBOutlet weak var snacksLegendPercent      : UILabel!
    @IBOutlet weak var breakfastLegendPercent   : UILabel!
    @IBOutlet weak var lunchLegendPercent       : UILabel!
    @IBOutlet weak var dinnerLegendPercent      : UILabel!
    @IBOutlet weak var totalGallonsLabel        : UILabel!
    @IBOutlet weak var dateOne                  : UILabel!
    @IBOutlet weak var dateTwo                  : UILabel!
    @IBOutlet weak var dateThree                : UILabel!
    @IBOutlet weak var recent1Name              : UILabel!
    @IBOutlet weak var recent1Total             : UILabel!
    @IBOutlet weak var recent1Serving           : UILabel!
    @IBOutlet weak var recent2Name              : UILabel!
    @IBOutlet weak var recent2Total             : UILabel!
    @IBOutlet weak var recent2Serving           : UILabel!
    
    //UIView
    @IBOutlet weak var circleView               : UIView!
    @IBOutlet weak var addMealMenu              : UIView!
    @IBOutlet weak var pieChart                 : UIView!
    @IBOutlet weak var barOne                   : UIView!
    @IBOutlet weak var barTwo                   : UIView!
    @IBOutlet weak var barThree                 : UIView!
    @IBOutlet weak var shadowView1              : UIView!
    @IBOutlet weak var shadowView2              : UIView!
    @IBOutlet weak var shadowView3              : UIView!
    @IBOutlet weak var limitShadowView          : UIView!
    @IBOutlet weak var averageShadowView        : UIView!
    @IBOutlet weak var recent1Shadow            : UIView!
    @IBOutlet weak var recent2Shadow            : UIView!
    
    @IBOutlet weak var leftArrow                : UIButton!
    @IBOutlet weak var rightArrow               : UIButton!
    
    @IBOutlet weak var scrollView               : UIScrollView!
    
    @IBOutlet weak var recentImage1             : UIImageView!
    @IBOutlet weak var recentImage2             : UIImageView!
    
    var dailyGoal                               : Double!
    var homeCircle                              : CirclePath!
    var homeTrack                               : CirclePath!
    var breakfastCircle                         : CirclePath!
    var lunchCircle                             : CirclePath!
    var dinnerCircle                            : CirclePath!
    var snacksCircle                            : CirclePath!
    var pieChartTrack                           : CirclePath!
    var barOnePath                              : LinePath!
    var barTwoPath                              : LinePath!
    var barThreePath                            : LinePath!
    
    let today = Date()
    let databaseDateFormatter = DateFormatter()
    let labelDateFormatter = DateFormatter()
    let dayDateFormatter = DateFormatter()
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
        
        let views = [shadowView1, shadowView2, shadowView3, limitShadowView, averageShadowView, recent1Shadow, recent2Shadow]
        for view in views {
            view?.layer.shadowColor = UIColor(red: 218/255, green: 218/255, blue: 218/255, alpha: 1.0).cgColor
            view?.layer.shadowOffset = CGSize(width: 1, height: 3)
            view?.layer.shadowOpacity = 1.0
            view?.layer.shadowRadius = 2.0
            view?.layer.masksToBounds = false
            view?.layer.shadowPath = UIBezierPath(roundedRect: view!.bounds, cornerRadius: 4).cgPath
        }
    }
    
    func setUpDateFormatter() {
        databaseDateFormatter.timeStyle = .none
        databaseDateFormatter.dateStyle = .long
        databaseDateFormatter.string(from: today)
        labelDateFormatter.timeStyle = .none
        labelDateFormatter.dateStyle = .long
        labelDateFormatter.dateFormat = "MMMM d"
        dayDateFormatter.timeStyle = .none
        dayDateFormatter.dateStyle = .long
        dayDateFormatter.dateFormat = "MM d"
        dateLabel.text = labelDateFormatter.string(from: today)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadData()
    }
    
    func loadData() {
        self.addMealMenu.alpha = 0.0
        let group = DispatchGroup()
        group.enter()
        userRef.getDocument { (doc, error) in
            if let doc = doc, doc.exists {
                self.dailyGoal = doc.data()!["water_goal"] as? Double
                self.limitLabel.text = String(Int(self.dailyGoal))
                let rawRecent = doc.get("recent")
                if rawRecent != nil {
                    recent = doc.get("recent") as! [[String : Any]]
                    self.showRecent()
                }
                group.leave()
            } else {
                // Display error screen
                print("Document does not exist")
            }
        }
        group.notify(queue: .main) {
            self.getTotalForDay()
        }
    }
    
//    func setStatusLabel(total: Int) {
//        let goal = Int(dailyGoal)
//        if (total == 0) {
//            statusLabel.text = "Enter some meals!"
//        } else if (total > goal) {
//            statusLabel.text = "Oh no, you've exceeded your limit."
//        } else if (total < goal/2) {
//            statusLabel.text = "You're doing great, keep it up!"
//        } else {
//            statusLabel.text = "It looks like you're nearing your limit."
//        }
//    }
    
    func drawLine(view: UIView, line: LinePath, cur: Float, max: Float, color: UIColor, width: Int, animate: Bool) {
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
    
    func initCircle() {
        let pathRect = CGRect(x: 0, y: 0, width: circleView.bounds.width, height: circleView.bounds.height)
        homeCircle = CirclePath(frame: pathRect)
        homeCircle.width = 12
        homeCircle.transform = CGAffineTransform(rotationAngle: CGFloat(3*CFloat.pi/2))
        homeCircle.roundedLineCap = true
        homeTrack = CirclePath(frame: pathRect)
        homeTrack.color = UIColor(red: 213/255, green: 213/255, blue: 213/255, alpha: 1.0).cgColor
        homeTrack.width = 5
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
        drawSlice(slice: dinnerCircle, percentLabel: dinnerLegendPercent, percentage: dinnerPercentage, startAngle: (breakfastPercentage+lunchPercentage), color: periwinkle)
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
    
    /** Bar chart code, not yet fully implemented
     **
    
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
    
    func showRecent(){
        let images = [recentImage1, recentImage2]
        let names = [recent1Name, recent2Name]
        let totals = [recent1Total, recent2Total]
        let servingSize = [recent1Serving, recent2Serving]
 
        for (index, i) in recent.enumerated() {
            if let ref = i["reference"] as? DocumentReference {
                ref.getDocument { (document, error) in
                    if let document = document {
                        let ingredient = Ingredient(document: document)
                        names[index]?.text = ingredient.name.capitalized
                        if let category = ingredient.category {
                           images[index]?.image = UIImage(named: category)
                        }
                        totals[index]?.text = String(Int(ingredient.waterData)) + " gal"
                        servingSize[index]?.text = String(Int(ingredient.waterData)) + " gal / " + String(format: "%.2f", ingredient.servingSize!) + " oz"
                    } else {
                        print("Document does not exist")
                    }
                }
            } else {
                guard let item_name = i["name"] as? String else { return }
                names[index]?.text = item_name.capitalized
                guard let image_name = i["image"] as? String else { return }
                images[index]?.image = UIImage(named: image_name)
                guard let water_total = i["total"] as? Double else { return }
                totals[index]?.text = String(Int(water_total)) + " gal"
                servingSize[index]?.isHidden = true
            }
        }
    }
    
    func getTotalForDay() {
        day.getDocument { (document, error) in
            if let document = document, document.exists {
                let breakfastTotal = self.getMealTotalForDay(meal: "Breakfast_total", document: document)
                let lunchTotal = self.getMealTotalForDay(meal: "Lunch_total", document: document)
                let dinnerTotal = self.getMealTotalForDay(meal: "Dinner_total", document: document)
                let snacksTotal = self.getMealTotalForDay(meal: "Snacks_total", document: document)
                let total = breakfastTotal + lunchTotal + dinnerTotal + snacksTotal
                self.updateCircle(circle: self.homeCircle, label: self.percentLabel, total: Float(total), limit: Float(self.dailyGoal))
                self.updatePieChart(breakfast: breakfastTotal, lunch: lunchTotal, dinner: dinnerTotal, snacks: snacksTotal, dailyTotal: total)
                self.getAverage(total: Int(total))
            }
        }
    }
    
    func getMealTotalForDay(meal: String, document: DocumentSnapshot) -> Double {
        if let total = document.data()![meal]{
            var totalAsDouble = total as! Double
            totalAsDouble.round()
            return totalAsDouble
        } else {
            return 0.0
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        if(offset == 0){
            leftArrow.isHidden = true
            rightArrow.isHidden = false
        }else if(offset > 0 && offset <= view.bounds.width){
            leftArrow.isHidden = false
            rightArrow.isHidden = true
        }else if(offset > view.bounds.width){
            rightArrow.isHidden = true
        }
    }
    
    /* IBActions ********************************************************************************************************/
    @IBAction func rightArrowTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.scrollView.contentOffset.x += self.view.bounds.width
        })
    }
    
    @IBAction func leftArrowTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.scrollView.contentOffset.x -= self.view.bounds.width
        })
    }
    
    @IBAction func breakfastTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.mealType = "Breakfast"
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func lunchTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.mealType = "Lunch"
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func dinnerTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.mealType = "Dinner"
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func snacksTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealViewController") as! MealViewController
        destination.mealType = "Snacks"
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func settingsBtnTapped(_ sender: Any) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    @IBAction func addBtnTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.3, animations: {
            self.addMealMenu.alpha = 1.0
        })
    }
    
    @IBAction func closeMealMenu(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3, animations: {
            self.addMealMenu.alpha = 0.0
        })
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
    
    func getAverage(total: Int) {
        var map = [String : Any]()
        let today = self.dayDateFormatter.string(from: self.today)
        userRef.getDocument { (doc, error) in
            if let doc = doc, doc.exists {
                let data = doc.get("average")
                if (data != nil) {
                    let average = data as! [String : Any]
                    if (average["day"] as! String == today) {
                        if ((average["days"] as! Int) == 1) {
                            map = ["day": today, "days": average["days"]!, "totalDay": total, "totalOverall": total]
                            self.averageLabel.text = String(total)
                        } else {
                            map = ["day": today, "days": average["days"]!, "totalDay": total, "totalOverall": average["totalOverall"]!]
                            let avg = (average["totalOverall"] as! Int)/(average["days"] as! Int)
                            self.averageLabel.text = String(avg)
                        }
                    } else {
                        let newOverallTotal = (average["totalOverall"] as! Int) + (average["totalDay"] as! Int)
                        let newNumDays = (average["days"] as! Int) + 1
                        map = ["day": today, "days": newNumDays, "totalDay": total, "totalOverall": newOverallTotal]
                        self.averageLabel.text = String(newOverallTotal/newNumDays)
                    }
                } else {
                    map = ["day": today, "days": 1, "totalDay": total, "totalOverall": total]
                    self.averageLabel.text = String(total)
                }
                self.userRef.setData(["average" : map], options: SetOptions.merge())
            } else {
                print("Document does not exist")
            }
        }
    }
    
    /*func scrollViewDidEndDecelerating(_ scrollView: UIScrollView){
        let pageWidth:CGFloat = scrollView.frame.width
        let currentPage:CGFloat = floor((scrollView.contentOffset.x-pageWidth/2)/pageWidth)+1
        if(currentPage == 2){
            //dateLabel.text = "Past 10 Days"
            dateLabel.text = labelDateFormatter.string(from: today)
        }else{
            dateLabel.text = labelDateFormatter.string(from: today)
        }
        self.pageControl.currentPage = Int(currentPage)
    }*/
}

