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
        
        cell.label.text = food.name.capitalized
        
        if let quantity = food.quantity {
            if let servingSize = food.servingSize {
                cell.gallonsWaterLabel.text = String(Int(food.waterData) * quantity) + " gal"
                let str = quantity > 1 ? " servings" : " serving"
                cell.gallonsPerServing.text = String(Int(quantity)) + str
            }
        }
        
        if(food.type == "USDA" || food.type == "Scanned"){
            cell.gallonsPerServing.isHidden = true
        } else {
            cell.gallonsPerServing.isHidden = false
        }

        return cell
    }
    
    //When the user selects a row, show the ingredient details page
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ingredientToShow = ingredientsInMeal[indexPath.row]
        let destination = self.storyboard?.instantiateViewController(withIdentifier: "IngredientInfo") as! IngredientInfoViewController
        destination.ingredientToShow = ingredientToShow
        present(destination, animated: true, completion: nil)
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
                        currentTotal = currentTotal - (Int(deletedIngredient.waterData) * deletedIngredient.quantity!)
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
                    map = ["name" : ing.name, "total" : ing.waterData, "ingredients": ing.ingredients as Any, "quantity" : ing.quantity ?? 1, "type" : ing.type]
                }
                foodInMeal.append(map)
            }
            
            day.setData([mealType : foodInMeal], options: SetOptions.merge())
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
