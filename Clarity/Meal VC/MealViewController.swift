//
//  MealViewController.swift
//  Clarity
//
//  Created by Henry Ball on 5/14/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SDWebImage
import FirebaseStorageUI
import GoogleSignIn

class MealViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var mealType: String!
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var gallonsInMeal: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    var ingredientsInMeal = [Ingredient]()
    var itemsInMeal = [Food]()
    let storage = Storage.storage()
    var mealWaterTotal: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        setBannerImage()
        //label showing gallons doesn't currently work
        self.gallonsInMeal.text = String(Int(self.ingredientsInMeal.map({$0.waterData}).reduce(0, +)))
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        queryIngredients()
    }
    
    func setBannerImage(){
        switch mealType {
        case "breakfast":
            bannerImage.image = #imageLiteral(resourceName: "breakfastBanner")
        case "lunch":
            bannerImage.image = #imageLiteral(resourceName: "lunchBanner")
        case "dinner":
            bannerImage.image = #imageLiteral(resourceName: "dinnerBanner")
        case "snacks":
            bannerImage.image = #imageLiteral(resourceName: "snacksBanner")
        default:
            print("error")
        }
    }
    
    func queryIngredients() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
        
        let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(formatter.string(from: today))
        
        var ingredientReferences = [DocumentReference]()
        //var food = [Food]()
        
        day.getDocument { (document, error) in
            if(document?.exists)!{
                //get ingredients
                if(document?.data()?.keys.contains(self.mealType))!{
                    ingredientReferences = document?.data()![self.mealType] as! [DocumentReference]
                }
                
                if(document?.data()?.keys.contains("total_water_day"))!{
                    //self.mealWaterTotal = document?.data()!["total_water_day"] as! Double
                    self.gallonsInMeal.text = String(Int(document?.data()!["total_water_day"] as! Double))
                }
                
                self.ingredientsInMeal = []
                for ref in ingredientReferences {
                    ref.getDocument { (document, error) in
                        if let document = document {
                            self.ingredientsInMeal.append(Ingredient(document: document))
                            self.tableView.reloadData()
                        } else {
                            print("Document does not exist")
                        }
                    }
                }
                
                //get food
                if(document?.data()?.keys.contains(self.mealType + "-meals"))!{
                    for doc in (document?.data())!{
                       //food.append(Food(document: doc))
                        print("------")
                        print(doc.key)
                        print("------")
                        print(doc.value)
                        print("------")
                    }
                }
            } else {
                print("No ingredients")
            }
        }
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func addTapped(_ sender: UIButton) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealAddItemViewController") as! MealAddItemViewController
        destination.mealType = mealType
        destination.ingredientsInMeal = ingredientsInMeal
        self.navigationController?.pushViewController(destination, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell") as! IngredientCell
        cell.label.text = ingredientsInMeal[indexPath.row].name
        let imagePath = "food-icons/" + ingredientsInMeal[indexPath.row].name.uppercased() + ".jpg"

        let imageRef = storage.reference().child(imagePath)
        cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewHeight.constant = CGFloat(Double(ingredientsInMeal.count)*75.0)
        return ingredientsInMeal.count
    }
}
