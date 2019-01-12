//
//  searchViewControllerDelegateExtension.swift
//  Clarity
//
//  Created by Celine Pena on 8/18/18.
//  Copyright © 2018 Clarity. All rights reserved.
//
import UIKit

//Contains all of the UITableView Delegate/Data Source functions
extension SearchViewController {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchedProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "searchCell") as! SearchCell
        cell.label.text = searchedProducts[indexPath.row].name.capitalized
        return cell
    }
    
    //When the user selects a row, gets the quantity and calls addItemToList()
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let currentCell = tableView.cellForRow(at: indexPath) as! SearchCell
        let food = searchedProducts[indexPath.row]
        
        let quantity = Int(currentCell.quantityTextField.text!)
        addItemToList(number: food.ndbno, name: food.name, quantity: quantity!)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = searchedProducts[indexPath.row]
        if let index = ingredientsInMeal.index(where: { $0.name == item.name }) {
            ingredientsInMeal.remove(at: index)
        }
        
        if let index = addedIngredients.index(where: { $0.name == item.name }) {
            addedIngredients.remove(at: index)
        }
    }
}
