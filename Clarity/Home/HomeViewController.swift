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
var ingredientsFromDatabase  = [Ingredient]()
var proteins                 = [Ingredient]()
var fruits                   = [Ingredient]()
var vegetables               = [Ingredient]()
var dairy                    = [Ingredient]()
var drinks                   = [Ingredient]()
var grains                   = [Ingredient]()
var other                    = [Ingredient]()
var recent                   = [[String: Any]]()
var recentsAsIngredient      = [Ingredient?](repeating: nil, count: 2)
let orange                   = UIColor(red: 255/255, green: 109/255, blue: 109/255, alpha: 1)
let periwinkle               = UIColor(red: 153/255, green: 192/255, blue: 243/255, alpha: 1)
let blue                     = UIColor(red: 154/255, green: 225/255, blue: 241/255, alpha: 1)
let darkBlue                 = UIColor(red: 107/255, green: 161/255, blue: 228/255, alpha: 1)
let yellow                   = UIColor(red: 255/255, green: 215/255, blue: 130/255, alpha: 1)
let green                   = UIColor(red: 158/255, green: 220/255, blue: 154/255, alpha: 1)

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
    @IBOutlet weak var infoViewName             : UILabel!
    @IBOutlet weak var infoViewGallons: UILabel!
    @IBOutlet weak var infoViewCategory: UILabel!
    @IBOutlet weak var infoViewRatingLabel: UILabel!
    @IBOutlet weak var infoViewPercentileLabel: UILabel!
    @IBOutlet weak var infoViewSource: UILabel!
    
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
    @IBOutlet weak var infoView                 : UIView!
    @IBOutlet weak var infoViewLine: UIView!
    @IBOutlet weak var infoViewRatingBoarder: UIView!
    
    @IBOutlet weak var leftArrow                : UIButton!
    @IBOutlet weak var rightArrow               : UIButton!
    
    @IBOutlet weak var scrollView               : UIScrollView!
    
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
        initInfoView()
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
    
    override func viewWillAppear(_ animated: Bool) {
        loadData()
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
    
    func initInfoView() {
        infoView.alpha = 0.0
        infoViewLine.layer.cornerRadius = infoViewLine.bounds.height/2
        infoViewRatingBoarder.layer.borderWidth = 2.0
        infoViewRatingBoarder.layer.cornerRadius = infoViewRatingBoarder.bounds.height/2
    }
    
    func loadData() {
        self.addMealMenu.alpha = 0.0
        self.infoView.alpha = 0.0
        let group = DispatchGroup()
        group.enter()
        userRef.getDocument { (doc, error) in
            if let doc = doc, doc.exists {
                self.dailyGoal = doc.data()!["water_goal"] as? Double
                //self.limitLabel.text = String(Int(self.dailyGoal)) + "gal"
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
    
    func getTotalForDay() {
        day.getDocument { (document, error) in
            if let document = document, document.exists {
                let breakfastTotal = self.getMealTotalForDay(meal: "Breakfast_total", document: document)
                let lunchTotal = self.getMealTotalForDay(meal: "Lunch_total", document: document)
                let dinnerTotal = self.getMealTotalForDay(meal: "Dinner_total", document: document)
                let snacksTotal = self.getMealTotalForDay(meal: "Snacks_total", document: document)
                let total = breakfastTotal + lunchTotal + dinnerTotal + snacksTotal
                self.limitLabel.text = String(Int(self.dailyGoal) - Int(total)) + " gal"
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
                            self.averageLabel.text = String(total) + " gal"
                        } else {
                            map = ["day": today, "days": average["days"]!, "totalDay": total, "totalOverall": average["totalOverall"]!]
                            let avg = (average["totalOverall"] as! Int)/(average["days"] as! Int)
                            self.averageLabel.text = String(avg) + " gal"
                        }
                    } else {
                        let newOverallTotal = (average["totalOverall"] as! Int) + (average["totalDay"] as! Int)
                        let newNumDays = (average["days"] as! Int) + 1
                        map = ["day": today, "days": newNumDays, "totalDay": total, "totalOverall": newOverallTotal]
                        self.averageLabel.text = String(newOverallTotal/newNumDays) + " gal"
                    }
                } else {
                    map = ["day": today, "days": 1, "totalDay": total, "totalOverall": total]
                    self.averageLabel.text = String(total) + " gal"
                }
                self.userRef.setData(["average" : map], options: SetOptions.merge())
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func showRecent(){
        //let images = [recentPoint1, recentPoint2]
        let names = [recent1Name, recent2Name]
        let totals = [recent1Total, recent2Total]
        let servingSize = [recent1Serving, recent2Serving]
        
        for (index, i) in recent.enumerated() {
            if let ref = i["reference"] as? DocumentReference {
                ref.getDocument { (document, error) in
                    if let document = document {
                        let ingredient = Ingredient(document: document)
                        recentsAsIngredient[index] = ingredient
                        names[index]?.text = ingredient.name.capitalized
                        //if let category = ingredient.category {
                            //images[index]?.backgroundColor = self.setColor(category: category)
                            //images[index]?.layer.cornerRadius = (images[index]?.bounds.width)!/2
                        //}
                        totals[index]?.text = String(Int(ingredient.waterData/ingredient.servingSize!) * ingredient.quantity!) + " gal"
                        servingSize[index]?.text = String(ingredient.quantity!) + " ounces"
                    } else {
                        print("Document does not exist")
                    }
                }
            } else {
                // ***
                // *** Do we need this??
                // ***
                guard let item_name = i["name"] as? String else { return }
                names[index]?.text = item_name.capitalized
                //guard let category = i["category"] as? String else { return }
                //images[index]?.backgroundColor = setColor(category: category)
                //images[index]?.layer.cornerRadius = (images[index]?.bounds.width)!/2
                guard let water_total = i["total"] as? Double else { return }
                totals[index]?.text = String(Int(water_total)) + " gal"
                servingSize[index]?.isHidden = true
            }
        }
    }
    
    func fillInfoView(index: Int) {
        let ingredient = recentsAsIngredient[index]!
        infoViewName.text = ingredient.name.capitalized
        infoViewGallons.text = String(Int((ingredient.waterData))) + " gal / " + String(format: "%.2f", ingredient.servingSize!) + "oz"
        infoViewCategory.text = ingredient.category
        let percentile = calcPercentile(ingredient: ingredient)
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        let suffixAdded = formatter.string(from: NSNumber(value: percentile))
        infoViewPercentileLabel.text = suffixAdded! + " percentile of " + (ingredient.category!)
        setRating(percentile: percentile, view: infoViewRatingBoarder, label: infoViewRatingLabel)
        infoViewSource.text = ingredient.source
    }
    
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
                    case "grains":
                        grains.append(current_ingredient)
                    case "other":
                        other.append(current_ingredient)
                    default:
                        print("some item not in a category has been entered")
                    }
                }
            }
        }
    }
    
    /*func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    }*/
    
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

    @IBAction func closeInfoView(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3, animations: {
            self.infoView.alpha = 0.0
        })
    }
    
    @IBAction func recentBtnOne(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.fillInfoView(index: 0)
            self.infoView.alpha = 1.0
        })
    }
    
    @IBAction func recentBtnTwo(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: {
            self.fillInfoView(index: 1)
            self.infoView.alpha = 1.0
        })
    }
}

