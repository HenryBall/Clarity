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
    let storage = Storage.storage()
    
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        setUpView()
        queryIngredients()
        // Do any additional setup after loading the view.
    }
    
    func setUpView(){
        
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
        
        day.getDocument { (document, error) in
            if(document?.exists)!{
                if(document?.data()?.keys.contains(self.mealType))!{
                 ingredientReferences = document?.data()![self.mealType] as! [DocumentReference]
                
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
                }
            } else {
                print("No ingredients")
            }
        }
        self.gallonsInMeal.text = String(Int(self.ingredientsInMeal.map({$0.waterData}).reduce(0, +)))
    }
    
    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func addTapped(_ sender: UIButton) {
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "MealAddItemViewController") as! MealAddItemViewController
        destination.mealType = mealType
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
        cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Breakfast"))
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewHeight.constant = CGFloat(Double(ingredientsInMeal.count)*75.0)
        return ingredientsInMeal.count
    }
}
