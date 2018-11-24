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
let orange                   = UIColor(red: 252/255, green: 108/255, blue: 108/255, alpha: 1)
let periwinkle               = UIColor(red: 72/255, green: 112/255, blue: 164/255, alpha: 1)
let blue                     = UIColor(red: 132/255, green: 219/255, blue: 239/255, alpha: 1)
let darkBlue                 = UIColor(red: 72/255, green: 112/255, blue: 164/255, alpha: 1)
let yellow                   = UIColor(red: 255/255, green: 215/255, blue: 130/255, alpha: 1)
let green                    = UIColor(red: 158/255, green: 220/255, blue: 154/255, alpha: 1)

/** Main screen of the application
 ## Contains: ##
 1. Settings Button (top left)
 2. Add Button (top right)
 3. Scrolling view displaying percent of daily limit, daily intake per meal
 4. Gallons remaining until limit, daily average
 5. Recently added items and their data
 */
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
    @IBOutlet weak var recent1Name              : UILabel!
    @IBOutlet weak var recent1Total             : UILabel!
    @IBOutlet weak var recent1Serving           : UILabel!
    @IBOutlet weak var recent2Name              : UILabel!
    @IBOutlet weak var recent2Total             : UILabel!
    @IBOutlet weak var recent2Serving           : UILabel!
    @IBOutlet weak var recentEmptyMessage: UIView!
    
    //UIView
    @IBOutlet weak var circleView               : UIView!
    @IBOutlet weak var addMealMenu              : UIView!
    @IBOutlet weak var pieChart                 : UIView!
    @IBOutlet weak var shadowView1              : UIView!
    @IBOutlet weak var shadowView2              : UIView!
    @IBOutlet weak var limitShadowView          : UIView!
    @IBOutlet weak var averageShadowView        : UIView!
    @IBOutlet weak var recent1Shadow            : UIView!
    @IBOutlet weak var recent2Shadow            : UIView!
    @IBOutlet weak var infoView                 : UIView!
    
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
        print(defaults.string(forKey: "user_id")!)
        day = userRef.collection("meals").document(databaseDateFormatter.string(from: today))
        queryIngredientsFromFirebase()
        initCircle()
        initPieChart()
        let views = [shadowView1, shadowView2, limitShadowView, averageShadowView, recent1Shadow, recent2Shadow, recentEmptyMessage]
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

    func loadData() {
        self.addMealMenu.alpha = 0.0
        //self.infoView.alpha = 0.0
        let group = DispatchGroup()
        group.enter()
        userRef.getDocument { (doc, error) in
            if let doc = doc, doc.exists {
                self.dailyGoal = doc.data()!["water_goal"] as? Double
                if let rawRecent = doc.get("recent"){
                    recent = rawRecent as! [[String : Any]]
                    self.showRecent()
                } else {
                    self.toggleRecentEmptyState(hideRecent: true, hideLabel: false)
                }
                group.leave()
            } else {
                self.displayAlert()
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
    
    func toggleRecentEmptyState(hideRecent: Bool, hideLabel: Bool){
        recent1Shadow.isHidden = hideRecent
        recent2Shadow.isHidden = hideRecent
        recentEmptyMessage.isHidden = hideLabel
    }
    
    func showRecent() {
        toggleRecentEmptyState(hideRecent: false, hideLabel: true)
        let names = [recent1Name, recent2Name]
        let totals = [recent1Total, recent2Total]
        let servingSize = [recent1Serving, recent2Serving]
        for (i, elem) in recent.enumerated() {
            if let ref = elem["reference"] as? DocumentReference {
                ref.getDocument { (document, error) in
                    let ingredient = Ingredient(document: document!)
                    let quantity = elem["quantity"] as! Int
                    let str = quantity > 1 ? " ounces" : " ounce"
                    recentsAsIngredient[i] = ingredient
                    names[i]?.text = ingredient.name.capitalized
                    totals[i]?.text = String(Int(ingredient.waterData/ingredient.servingSize!) * quantity) + " gal"
                    servingSize[i]?.text = String(quantity) + str
                }
            } else {
                displayAlert()
            }
        }
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
    
    /* ------------------- IBActions ---------------------- */
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
    
    @IBAction func recentBtnOne(_ sender: UIButton) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "IngredientInfo") as! IngredientInfoViewController
        destination.ingredientToShow = recentsAsIngredient[0]
        present(destination, animated: true, completion: nil)
    }
    
    @IBAction func recentBtnTwo(_ sender: UIButton) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "IngredientInfo") as! IngredientInfoViewController
        destination.ingredientToShow = recentsAsIngredient[1]
        present(destination, animated: true, completion: nil)
    }
    
    func displayAlert() {
        let alert = UIAlertController(title: "Uh Oh", message: "There was an error, try restarting the app.", preferredStyle: UIAlertControllerStyle.alert)
        self.present(alert, animated: true, completion: nil)
    }
}

