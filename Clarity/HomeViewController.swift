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
    
    @IBOutlet weak var dailyTotalLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var todaysTotal: Double!
    var dailyGoal : Double!
    
    @IBOutlet weak var scrollView: UIScrollView!
    let shapeLayer = CAShapeLayer()
    
    let today = Date()
    let databaseDateFormatter = DateFormatter()
    let labelDateFormatter = DateFormatter()
    
    var user: String!
    var userRef: DocumentReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        user = defaults.string(forKey: "user_id")!
        userRef = db.collection("users").document(user)
        
        databaseDateFormatter.timeStyle = .none
        databaseDateFormatter.dateStyle = .long
        databaseDateFormatter.string(from: today)
        labelDateFormatter.timeStyle = .none
        labelDateFormatter.dateStyle = .long
        labelDateFormatter.dateFormat = "EEEE, MMM d"
        dateLabel.text = labelDateFormatter.string(from: today)
        
        self.scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width * 3, height:self.scrollView.frame.height)
        
        self.navigationController?.isNavigationBarHidden = true
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
            self.queryIngredientsFromFirebase()
        }
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
                        print(current_ingredient.category)
                    }
                }
            }
        }
    }
    
    func getTodaysTotal() {
        let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(databaseDateFormatter.string(from: today))
        
        firebaseHelper.getTotalForDay(day: day) { (total, error) in
            if let error = error {
                print (error)
            } else {
                let totalAsString = String(Int(total))
                if (totalAsString != self.dailyTotalLabel.text) {
                    self.drawCircle(dailyTotal: CGFloat(total))
                    self.dailyTotalLabel.text = totalAsString
                }
            }
        }
    }
    
    /* Circle Animation ************************************************************************************************/
    func drawCircle(dailyTotal: CGFloat) {
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
        
        let percentage = Int(( dailyTotal / CGFloat(dailyGoal)) * 100)
        percentLabel.text = String(describing: percentage) + "% of your daily limit"

        let endAngle = (CGFloat.pi / 2) + (CGFloat.pi * 2 * (dailyTotal / CGFloat(dailyGoal)))
        let motionPath = UIBezierPath(arcCenter: center, radius: 90, startAngle: CGFloat.pi / 2, endAngle: endAngle , clockwise: true)
        shapeLayer.path = motionPath.cgPath
        
        shapeLayer.strokeColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0).cgColor
        shapeLayer.lineWidth = 20
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.strokeEnd = 0
        
        view.layer.addSublayer(shapeLayer)
        scrollView.layer.addSublayer(shapeLayer)
        animateBar()
    }
    
    @objc private func animateBar() {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.toValue = 1
        basicAnimation.duration = 1
        basicAnimation.fillMode = kCAFillModeForwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
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
