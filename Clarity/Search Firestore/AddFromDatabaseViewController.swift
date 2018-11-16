//
//  AddFromDatabaseViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/17/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import UIKit
import FirebaseStorageUI
import Firebase

/** Presents a list of ingredients from Firestore and allows the user to select multiple and add them to this meal.
 ## Relevant classes: ##
 - addDatabaseIngredientCell : table view cell to display name, image, total gallons of water, quantity and add button for each ingredient
 */
class AddFromDatabaseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    /* IBOutlets */
    @IBOutlet weak var tableView    : UITableView!
    @IBOutlet weak var bannerImage  : UIImageView!
    @IBOutlet weak var searchBar    : UISearchBar!
    @IBOutlet weak var mealLabel    : UILabel!
    
    /* Class Globals */
    var mealType                    : String!
    var ingredientsInMeal           = [Ingredient]()
    var displayedIngredients        = [Ingredient]()
    var addedIngredients            = [Ingredient]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayedIngredients = ingredientsFromDatabase
        searchBar.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        setBannerImage(mealType: mealType, imageView: bannerImage, label: mealLabel)
        resetDisplayedIngredients()
    }
    
    /**
     When the user presses the "<" button, returns to HomeViewController
     - Parameter sender: "<" back button
    */
    @IBAction func backTapped(_ sender: UIButton) {
        resetDisplayedIngredients()
        self.navigationController?.popViewController(animated: true)
    }
    
    /**
     When the user presses the "add" button, updates the ingredients in the database and returns to HomeViewController
     - Parameter sender: "add" button on top right
    */
    @IBAction func doneTapped(_ sender: UIButton) {
        var allIngredients = [[String : Any]]()
        var ingredient = [String : Any]()
        
        for ingr in ingredientsInMeal {
            if(ingr.type == "Database"){
                let ref = db.document("water-footprint-data/" + ingr.name.capitalized)
                ingredient = ["reference" : ref, "quantity" : ingr.quantity ?? 1]
            } else {
                ingredient = ["name" : ingr.name, "total" : ingr.waterData, "ingredients": ingr.ingredients as Any, "image": ingr.imageName as Any, "quantity" : ingr.quantity ?? 1, "type" : ingr.type]
            }
            allIngredients.append(ingredient)
        }
        let total = ingredientsInMeal.map({Int($0.waterData/$0.servingSize!) * $0.quantity!}).reduce(0, +)
        day.setData([mealType + "_total" : total], options: SetOptions.merge())
        day.setData([mealType : allIngredients], options: SetOptions.merge())
        
        updateRecent()
        resetDisplayedIngredients()

        if let destination = self.navigationController?.viewControllers[1] {
            self.navigationController?.popToViewController(destination, animated: true)
        }
    }
    
    func resetDisplayedIngredients() {
        for ingr in displayedIngredients {
            ingr.quantity = 1
        }
    }
    
    /*func updateRecent() {
        // ***
        // *** Fix added ingredient quantites
        // ***
        //addedIngredients = ingredientsInMeal
        let userRef = db.collection("users").document(defaults.string(forKey: "user_id")!)
        var pushToDatabase = [[String : Any]]()
        
        /* crashes if add is presses but nothing is added with out this if */
        if (self.addedIngredients.count == 0) {
            return
        }
        
        if(self.addedIngredients.count == 1){
            for item in recent {
                if (item["index"] as? Int == 0){
                    if let itemRef = item["reference"] as? DocumentReference {
                        pushToDatabase.append(["index": 1, "reference": itemRef])
                    } else {
                        pushToDatabase.append(["index": 1, "image": item["image"], "name": item["name"], "total": item["total"]])
                    }
                }
            }
        }
        var index = 0
        if self.addedIngredients.count > 1 {
            index = addedIngredients.count-2
            let ref2 = db.document("water-footprint-data/" + self.addedIngredients[index+1].name.capitalized)
            pushToDatabase.append(["index": 1, "reference": ref2])
        }
        
        let ref1 = db.document("water-footprint-data/" + self.addedIngredients[index].name.capitalized)
        pushToDatabase.append(["index": 0, "reference": ref1])
        pushToDatabase.reverse()

        userRef.setData(["recent" : pushToDatabase], options: SetOptions.merge())
    }*/

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchText == ""){
            displayedIngredients = ingredientsFromDatabase
        } else {
            displayedIngredients = ingredientsFromDatabase.filter({$0.name.lowercased().contains(searchText.lowercased())})
        }
        self.tableView.reloadData()
    }
    
    func updateRecent() {
        let userRef = db.collection("users").document(defaults.string(forKey: "user_id")!)
        var pushToDb = [[String : Any]]()
        if (self.ingredientsInMeal.count == 0) {
            return
        } else {
            for ingr in self.ingredientsInMeal {
                let ref = db.document("water-footprint-data/" + ingr.name.capitalized)
                recent.insert(["reference": ref, "quantity": ingr.quantity!], at: 0)
                if (recent.count > 2) { recent.popLast() }
            }
        }
        for (i, elem) in recent.enumerated() {
            pushToDb.insert(["index": i, "reference": elem["reference"]!, "quantity": elem["quantity"]!], at: i)
        }
        userRef.setData(["recent" : pushToDb], options: SetOptions.merge())
        print (pushToDb)
    }
    
}
