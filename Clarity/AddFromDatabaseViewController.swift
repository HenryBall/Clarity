//
//  AddFromDatabaseViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/17/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseStorageUI
import Firebase

class AddFromDatabaseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bannerImage: UIImageView!
    var mealType: String!
    var ingredientsInMeal = [Ingredient]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        setBanner()
    }
    
    func setBanner(){
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
    
    @IBAction func backTapped(_ sender: UIButton) {
        let today = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
        
        let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(formatter.string(from: today))
        var refArray = [DocumentReference]()
        for i in ingredientsInMeal{
            let ref = db.document("water-footprint-data/" + i.name.capitalized)
            print(ref)
            refArray.append(ref)
        }

        day.setData([mealType : refArray], options: SetOptions.merge())
        
        self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addDatabaseIngredientCell") as! addDatabaseIngredientCell
        cell.label.text = ingredientsFromDatabase[indexPath.row].name
        let imagePath = "food-icons/" + ingredientsFromDatabase[indexPath.row].name.uppercased() + ".jpg"
        
        let imageRef = storage.reference().child(imagePath)
        cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ingredientsFromDatabase.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let currentIngredient = ingredientsFromDatabase[indexPath.row]
        //let cell = tableView.dequeueReusableCell(withIdentifier: "addDatabaseIngredientCell") as! addDatabaseIngredientCell
        //print(cell.count.text)
        //if let count = Int(cell.count.text!){
            //if(count > 1){
                //for i in 0 ... count{
                  //  ingredientsInMeal.append(currentIngredient)
                //}
            //}else{
                ingredientsInMeal.append(currentIngredient)
            //}
        //}
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = ingredientsFromDatabase[indexPath.row]
        if let index = ingredientsInMeal.index(where: { $0.name == item.name }) {
            ingredientsInMeal.remove(at: index)
        }
    }
}
