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

class AddFromDatabaseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bannerImage: UIImageView!
    var mealType: String!
    
    var foodInMeal = [[String : Any]]()
    var ingredientsInMeal = [Ingredient]()
    var displayedIngredients = [Ingredient]()
    
    let today = Date()
    let formatter = DateFormatter()
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(ingredientsInMeal)
        displayedIngredients = ingredientsFromDatabase
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
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
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneTapped(_ sender: UIButton) {
//        var map = [String : Any]()
//
//        for i in ingredientsInMeal{
//            if(i.source != ""){
//                let ref = db.document("water-footprint-data/" + i.name.capitalized)
//                map = ["name" : i.name, "total" : i.waterData, "quantity" : i.quantity]
//            }
//        }
        let total = ingredientsInMeal.map({$0.waterData}).reduce(0, +)
        day.setData([mealType + "_total" : total], options: SetOptions.merge())
        day.setData([mealType : foodInMeal], options: SetOptions.merge())
        
        if let destination = self.navigationController?.viewControllers[1] {
            self.navigationController?.popToViewController(destination, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addDatabaseIngredientCell") as! addDatabaseIngredientCell
        cell.label.text = displayedIngredients[indexPath.row].name.capitalized
        cell.gallonsWaterLabel.text = String(Int(displayedIngredients[indexPath.row].waterData))
        let imagePath = "food-icons/" + displayedIngredients[indexPath.row].name.uppercased() + ".jpg"
        let imageRef = storage.reference().child(imagePath)
        cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedIngredients.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        var map = [String : Any]()
        let ref = db.document("water-footprint-data/" + displayedIngredients[indexPath.row].name.capitalized)
        let currentCell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        let quantity = Int(currentCell.quantityTextField.text!)
        
        map = ["reference" : ref, "quantity" : quantity]
        self.foodInMeal.append(map)
        
        let currentIngredient = displayedIngredients[indexPath.row]
        ingredientsInMeal.append(currentIngredient)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = displayedIngredients[indexPath.row]
        if let index = ingredientsInMeal.index(where: { $0.name == item.name }) {
            ingredientsInMeal.remove(at: index)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //searchProducts(searchText: searchText)
        if(searchText == ""){
            displayedIngredients = ingredientsFromDatabase
        } else {
            // Filter the results
            displayedIngredients = ingredientsFromDatabase.filter({$0.name.lowercased().contains(searchText.lowercased())})
        }
        self.tableView.reloadData()
    }
}
