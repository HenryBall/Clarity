//
//  MealViewControllerDelegateExtension.swift
//  Clarity
//
//  Created by Celine Pena on 8/18/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import Foundation
import UIKit
import Firebase

//Contains all of the UITableView Delegate/Data Source functions
extension MealViewController {

    //Set the height of the table view cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85.0
    }
    
    //Set the name, # of gallons and image for each ingredient
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell") as! IngredientCell
        let food = ingredientsInMeal[indexPath.row]
        let amtPerOz = food.waterData / food.servingSize!
        
        cell.label.text = food.name.capitalized
        cell.gallonsWaterLabel.text = String(Int(amtPerOz) * food.quantity!) + " gal"
        //cell.gallonsPerServing.text = String(Int(food.waterData)) + " gal / " + String(format: "%.2f", food.servingSize!) + " oz"
        let str = (food.quantity! > 1) ? " ounces" : " ounce"
        cell.gallonsPerServing.text = String(food.quantity!) + str
        //if let category = food.category {
            //cell.point.backgroundColor = setColor(category: category)
            //cell.point.layer.cornerRadius = cell.point.bounds.width/2
        //}
        
        if(food.type == "USDA" || food.type == "Scanned"){
            cell.gallonsPerServing.isHidden = true
        } else {
            cell.gallonsPerServing.isHidden = false
        }

        return cell
    }
    
    //When the user selects a row, pop the ingredient details page onto the navigation stack
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.3, animations: {
            self.infoView.alpha = 1.0
        })
        let ingredient = ingredientsInMeal[indexPath.row]
        fillInfoView(ingredient: ingredient)
    }
    
    //Set the number of ingredients to show
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //tableViewHeight.constant = CGFloat(Double(ingredientsInMeal.count)*75.0)
        return ingredientsInMeal.count
    }
    
    //When a user swipes to delete an ingredient, need to decrease the total water intake for that meal, remove it from our ingredientsInMeal array and push the new values back up to the database
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let deletedIngredient = self.ingredientsInMeal[indexPath.row]
            
            day.getDocument { (document, error) in
                if(document?.exists)!{
                    if var currentTotal = document?.data()![self.mealType + "_total"] as? Int {
                        print(currentTotal)
                        print(deletedIngredient.waterData)
                        currentTotal = currentTotal - (Int(deletedIngredient.waterData/deletedIngredient.servingSize!) * deletedIngredient.quantity!)
                        self.gallonsInMeal.text = String(Int(currentTotal))
                        self.day.setData([self.self.mealType + "_total" : currentTotal], options: SetOptions.merge())
                    }
                }
            }
            
            self.ingredientsInMeal.remove(at: indexPath.row)
            
            var foodInMeal = [[String : Any]]()
            var map = [String : Any]()
            
            for ing in ingredientsInMeal {
                if(ing.type == "Database"){
                    let ref = db.document("water-footprint-data/" + ing.name.capitalized)
                    map = ["reference" : ref, "quantity" : ing.quantity ?? 1]
                } else {
                    map = ["name" : ing.name, "total" : ing.waterData, "ingredients": ing.ingredients as Any, "image": ing.imageName as Any, "quantity" : ing.quantity ?? 1, "type" : ing.type]
                }
                foodInMeal.append(map)
            }
            
            day.setData([mealType : foodInMeal], options: SetOptions.merge())
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func fillInfoView(ingredient: Ingredient) {
        tappedName.text = ingredient.name.capitalized
        //infoViewGallons.text = String(Int((ingredient.waterData))) + " gal / " + String(format: "%.2f", ingredient.servingSize!) + "oz"
        infoViewGallons.text = String(Int(ingredient.waterData/ingredient.servingSize!)) + " gallons per ounce"
        let str = (ingredient.servingSize! > 1) ? " ounces" : " ounce"
        infoViewCategory.text = "average serving size: " + String(Int(ingredient.servingSize!)) + str
        let percentile = calcPercentile(ingredient: ingredient)
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        let suffixAdded = formatter.string(from: NSNumber(value: percentile))
        infoViewPercentile.text = suffixAdded! + " percentile of " + ingredient.category!
        setRating(percentile: percentile, view: infoViewRatingBoarder, label: infoViewRatingLabel)
        infoViewSource.text = ingredient.source
    }
}
