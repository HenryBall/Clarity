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
        return 85.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addDatabaseIngredientCell") as! addDatabaseIngredientCell
        let food = displayedIngredients[indexPath.row]
        
        cell.label.text = displayedIngredients[indexPath.row].name.capitalized
        cell.gallonsWaterLabel.text = String(Int(food.waterData)) + " gal / " + String(format: "%.2f", food.servingSize!) + " oz"
        if let category = displayedIngredients[indexPath.row].category {
            cell.icon.image = UIImage(named: category)
        }
        setCellTags(cell: cell, index: indexPath.row)
        setCellTargets(cell: cell)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedIngredients.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        let currentIngredient = displayedIngredients[indexPath.row]
        let quantity = Int(cell.quantityTextField.text!)
        currentIngredient.quantity = quantity
        ingredientsInMeal.append(currentIngredient)
        addedIngredients.append(currentIngredient)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = displayedIngredients[indexPath.row]
        if let index = ingredientsInMeal.index(where: { $0.name == item.name }) {
            ingredientsInMeal.remove(at: index)
        }
        
        if let index = addedIngredients.index(where: { $0.name == item.name }) {
            addedIngredients.remove(at: index)
        }
    }
    
    func setCellTargets(cell: addDatabaseIngredientCell) {
        cell.count.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        cell.addButton.addTarget(self, action: #selector(addTapped(_:)), for: .touchUpInside)
        cell.subtractButton.addTarget(self, action: #selector(subTapped(_:)), for: .touchUpInside)
    }
    
    func setCellTags(cell: addDatabaseIngredientCell, index: Int) {
        cell.count.tag = index
        cell.addButton.tag = index
        cell.subtractButton.tag = index
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let index = textField.tag
        let name = displayedIngredients[index].name
        if let i = ingredientsInMeal.index(where: { $0.name == name }) {
            ingredientsInMeal[i].quantity = Int(textField.text!)
        }
    }
    
    @objc func addTapped(_ sender: UIButton){
        let index = sender.tag
        let name = displayedIngredients[index].name
        let indexPath = IndexPath(item: index, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        if let i = ingredientsInMeal.index(where: { $0.name == name }) {
            ingredientsInMeal[i].quantity = ingredientsInMeal[i].quantity! + 1
            cell.count.text = String(ingredientsInMeal[i].quantity!)
        } 
    }
    
    @objc func subTapped(_ sender: UIButton){
        let index = sender.tag
        let name = displayedIngredients[index].name
        let indexPath = IndexPath(item: index, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        if let i = ingredientsInMeal.index(where: { $0.name == name }) {
            if (ingredientsInMeal[i].quantity! > 1) {
                ingredientsInMeal[i].quantity = ingredientsInMeal[i].quantity! - 1
                cell.count.text = String(ingredientsInMeal[i].quantity!)
            }
        }
    }
}
