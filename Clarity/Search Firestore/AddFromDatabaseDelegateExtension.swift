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
        
        if let quantity = food.quantity {
            if let servingSize = food.servingSize {
                //cell.gallonsWaterLabel.text = String(Int(food.waterData) * quantity) + " gallons per " + String(Int(servingSize)) + " oz"
                cell.gallonsWaterLabel.text = String(Int(food.waterData) * quantity) + " gallons per serving"
                cell.quantityTextField.text = String(quantity)
            }
        }
        setCellTags(cell: cell, index: indexPath.row)
        setCellTargets(cell: cell)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedIngredients.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let currentIngredient = displayedIngredients[indexPath.row]
        addedIngredients.append(currentIngredient)
        print(currentIngredient.quantity!)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = displayedIngredients[indexPath.row]
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
        if let i = addedIngredients.index(where: { $0.name == name }) {
            if let quantity = addedIngredients[i].quantity {
                addedIngredients[i].quantity = quantity + 1
                cell.count.text = String(quantity + 1)
            }
        }
    }
    
    @objc func subTapped(_ sender: UIButton){
        let index = sender.tag
        let name = displayedIngredients[index].name
        let indexPath = IndexPath(item: index, section: 0)
        let cell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        if (displayedIngredients[index].quantity! > 1) {
            if let i = addedIngredients.index(where: { $0.name == name }) {
                if let quantity = addedIngredients[i].quantity {
                    addedIngredients[i].quantity = quantity - 1
                    cell.count.text = String(quantity - 1)
                }
            }
        }
    }
}
