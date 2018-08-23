//
//  searchViewControllerDelegateExtension.swift
//  Clarity
//
//  Created by Celine Pena on 8/18/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import UIKit

//Contains all of the UITableView Delegate/Data Source functions
extension searchViewController {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchedProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "searchCell") as! searchCell
        cell.label.text = searchedProducts[indexPath.row].name.capitalized
        return cell
    }
    
    //When the user selects a row, gets the quantity and calls addItemToList()
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let currentCell = tableView.cellForRow(at: indexPath) as! searchCell
        let food = searchedProducts[indexPath.row]
        
        let quantity = Int(currentCell.quantityTextField.text!)
        addItemToList(number: food.ndbno, name: food.name, quantity: quantity!)
    }
}
