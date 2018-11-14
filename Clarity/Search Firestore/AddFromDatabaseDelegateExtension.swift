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
        let amtPerOz = food.waterData / food.servingSize!
        cell.label.text = displayedIngredients[indexPath.row].name.capitalized
        //cell.gallonsWaterLabel.text = String(Int(food.waterData)) + " gal / " + String(format: "%.2f", food.servingSize!) + " oz"
        cell.gallonsWaterLabel.text = String(Int(amtPerOz)) + " gallons per ounce"
        cell.quantityTextField.text = String(food.quantity!) + " oz"
        //if let category = food.category {
            //cell.point.backgroundColor = setColor(category: category)
            //cell.point.layer.cornerRadius = cell.point.bounds.width/2
        //}
        setCellTags(cell: cell, index: indexPath.row)
        setCellTargets(cell: cell)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedIngredients.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let currentIngredient = displayedIngredients[indexPath.row]
        print(String(displayedIngredients[indexPath.row].quantity!))
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
        cell.addButton.addTarget(self, action: #selector(addTapped(_:)), for: .touchUpInside)
        cell.subtractButton.addTarget(self, action: #selector(subTapped(_:)), for: .touchUpInside)
    }
    
    func setCellTags(cell: addDatabaseIngredientCell, index: Int) {
        cell.count.tag = index
        cell.addButton.tag = index
        cell.subtractButton.tag = index
    }
    
    @objc func addTapped(_ sender: UIButton){
        let index = sender.tag
        let name = displayedIngredients[index].name
        print("add tapped on cell " + String(index) + " with name " + name)
        let indexPath = IndexPath(item: index, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        if let i = ingredientsInMeal.index(where: { $0.name == name }) {
            ingredientsInMeal[i].quantity = ingredientsInMeal[i].quantity! + 1
            cell.count.text = String(ingredientsInMeal[i].quantity!) + " oz"
        }
    }
    
    @objc func subTapped(_ sender: UIButton){
        let index = sender.tag
        let name = displayedIngredients[index].name
        let indexPath = IndexPath(item: index, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        if (displayedIngredients[index].quantity! > 1) {
            if let i = ingredientsInMeal.index(where: { $0.name == name }) {
                ingredientsInMeal[i].quantity = ingredientsInMeal[i].quantity! - 1
                cell.count.text = String(ingredientsInMeal[i].quantity!) + " oz"
            }
        }
    }
}
