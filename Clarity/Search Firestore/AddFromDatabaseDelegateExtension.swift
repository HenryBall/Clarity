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
        cell.count.tag = indexPath.row
        cell.addButton.tag = indexPath.row
        cell.subtractButton.tag = indexPath.row
        cell.label.text = displayedIngredients[indexPath.row].name.capitalized
        cell.gallonsWaterLabel.text = String(Int(displayedIngredients[indexPath.row].waterData))
        let imagePath = "food-icons/" + displayedIngredients[indexPath.row].name.uppercased() + ".jpg"
        let imageRef = storage.reference().child(imagePath)
        cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
        cell.count.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        cell.addButton.addTarget(self, action: #selector(addTapped(_:)), for: .touchUpInside)
        cell.subtractButton.addTarget(self, action: #selector(subTapped(_:)), for: .touchUpInside)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedIngredients.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let currentCell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        currentCell.backgroundColor = UIColor.lightGray
        currentCell.label.textColor = UIColor.white
        currentCell.gallonsWaterLabel.textColor = UIColor.white
        currentCell.gal.textColor = UIColor.white
        currentCell.addButton.setTitleColor(UIColor.white, for: [])
        currentCell.subtractButton.setTitleColor(UIColor.white, for: [])
        let quantity = Int(currentCell.quantityTextField.text!)
        let currentIngredient = displayedIngredients[indexPath.row]
        currentIngredient.quantity = quantity
        ingredientsInMeal.append(currentIngredient)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = displayedIngredients[indexPath.row]
        
        if let index = ingredientsInMeal.index(where: { $0.name == item.name }) {
            ingredientsInMeal.remove(at: index)
        }
        
        let currentCell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        currentCell.backgroundColor = UIColor.white
        currentCell.label.textColor = textColor
        currentCell.gallonsWaterLabel.textColor = textColor
        currentCell.gal.textColor = textColor
        currentCell.addButton.setTitleColor(textColor, for: [])
        currentCell.subtractButton.setTitleColor(textColor, for: [])
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
        let indexPath = IndexPath(item: index, section: 0)
        let currentCell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        let name = displayedIngredients[index].name
        if let i = ingredientsInMeal.index(where: { $0.name == name }) {
            ingredientsInMeal[i].quantity = ingredientsInMeal[i].quantity! + 1
            currentCell.count.text = String(ingredientsInMeal[i].quantity!)
        }
    }
    
    @objc func subTapped(_ sender: UIButton){
        let index = sender.tag
        let indexPath = IndexPath(item: index, section: 0)
        let currentCell = tableView.cellForRow(at: indexPath) as! addDatabaseIngredientCell
        let name = displayedIngredients[index].name
        if let i = ingredientsInMeal.index(where: { $0.name == name }) {
            if (ingredientsInMeal[i].quantity! > 1) {
                ingredientsInMeal[i].quantity = ingredientsInMeal[i].quantity! - 1
                currentCell.count.text = String(ingredientsInMeal[i].quantity!)
            }
        }
    }
}
