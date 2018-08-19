//
//  AddFromDatabaseDelegateExtension.swift
//  Clarity
//
//  Created by Celine Pena on 8/18/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import UIKit

extension AddFromDatabaseViewController {
    
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
        let currentCell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        currentCell.addButton.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        let quantity = Int(currentCell.quantityTextField.text!)
        
        let currentIngredient = displayedIngredients[indexPath.row]
        currentIngredient.waterData = currentIngredient.waterData * Double(quantity!)
        ingredientsInMeal.append(currentIngredient)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = displayedIngredients[indexPath.row]
        
        if let index = ingredientsInMeal.index(where: { $0.name == item.name }) {
            ingredientsInMeal.remove(at: index)
        }
        
        let currentCell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        currentCell.addButton.setImage(#imageLiteral(resourceName: "Add"), for: .normal)
    }
}
