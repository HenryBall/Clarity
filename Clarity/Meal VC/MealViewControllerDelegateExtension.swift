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
        return 75.0
    }
    
    //Set the name, # of gallons and image for each ingredient
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell") as! IngredientCell
        cell.label.text = ingredientsInMeal[indexPath.row].name.capitalized + " (x" + String(ingredientsInMeal[indexPath.row].quantity!) + ")"
        cell.gallonsWaterLabel.text = String(Int(ingredientsInMeal[indexPath.row].waterData) * ingredientsInMeal[indexPath.row].quantity!)
        cell.gallonsPerServing.text = String(Int(ingredientsInMeal[indexPath.row].waterData)) + " gal / " + String(format: "%.2f", ingredientsInMeal[indexPath.row].servingSize!) + " oz"
        let imagePath = "food-icons/" + ingredientsInMeal[indexPath.row].name.uppercased() + ".jpg"
        let imageRef = storage.reference().child(imagePath)
        cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
        return cell
    }
    
    //When the user selects a row, pop the ingredient details page onto the navigation stack
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = storyboard?.instantiateViewController(withIdentifier: "IngredientsDetailsViewController") as! IngredientsDetailsViewController
        destination.ingredientToShow = ingredientsInMeal[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(destination, animated: true)
    }
    
    //Set the number of ingredients to show
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewHeight.constant = CGFloat(Double(ingredientsInMeal.count)*75.0)
        return ingredientsInMeal.count
    }
    
    //When a user swipes to delete an ingredient, need to decrease the total water intake for that meal, remove it from our ingredientsInMeal array and push the new values back up to the database
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let deletedIngredient = self.ingredientsInMeal[indexPath.row]
            
            day.getDocument { (document, error) in
                if(document?.exists)!{
                    if var currentTotal = document?.data()![self.mealType + "_total"] as? Double {
                        currentTotal = currentTotal - (deletedIngredient.waterData * Double(deletedIngredient.quantity!))
                        self.gallonsInMeal.text = String(Int(currentTotal))
                        self.day.setData([self.self.mealType + "_total" : currentTotal], options: SetOptions.merge())
                    }
                }
            }
            
            self.ingredientsInMeal.remove(at: indexPath.row)
            
            var foodInMeal = [[String : Any]]()
            var map = [String : Any]()
            
            for ing in ingredientsInMeal {
                if(ing.source != ""){
                    let ref = db.document("water-footprint-data/" + ing.name.capitalized)
                    map = ["reference" : ref, "quantity" : ing.quantity ?? 1]
                } else {
                    map = ["name" : ing.name, "total" : ing.waterData, "quantity" : ing.quantity ?? 1]
                }
                foodInMeal.append(map)
            }
            
            day.setData([mealType : foodInMeal], options: SetOptions.merge())
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

}
