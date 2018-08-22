//
//  AddFromDatabaseViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/17/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseStorageUI
import Firebase

/** Presents a list of ingredients from Firestore and allows the user to select multiple and add them to this meal.
 ## Relevant classes: ##
 - addDatabaseIngredientCell : table view cell to display name, image, total gallons of water, quantity and add button for each ingredient
 */
class AddFromDatabaseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    /* IBOutlets */
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    /* Class Globals */
    var mealType: String!
    var ingredientsInMeal = [Ingredient]()
    var displayedIngredients = [Ingredient]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayedIngredients = ingredientsFromDatabase
        searchBar.delegate = self
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        setBanner()
    }
    
    /*
     - Set the header image based on the meal type
    */
    func setBanner(){
        switch mealType {
        case "breakfast":
            bannerImage.image = #imageLiteral(resourceName: "breakfastBanner")
        case "lunch":
            bannerImage.image = #imageLiteral(resourceName: "lunchBanner")
        case "dinner":
            bannerImage.image = #imageLiteral(resourceName: "dinnerBanner")
        case "snacks":
            bannerImage.image = #imageLiteral(resourceName: "snacksBanner")
        default:
            print("error")
        }
    }
    
    /*
     When the user presses the "<" button, returns to HomeViewController
     - Parameter sender: "<" back button
    */
    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /*
     When the user presses the "add" button, updates the ingredients in the database and returns to HomeViewController
     - Parameter sender: "add" button on top right
    */
    @IBAction func doneTapped(_ sender: UIButton) {
        var allIngredients = [[String : Any]]()
        var ingredient = [String : Any]()
        for ingr in ingredientsInMeal {
            if(ingr.source != ""){
                let ref = db.document("water-footprint-data/" + ingr.name.capitalized)
                ingredient = ["reference" : ref, "quantity" : ingr.quantity ?? 1]
            } else {
                ingredient = ["name" : ingr.name, "total" : ingr.waterData, "quantity" : ingr.quantity ?? 1]
            }
            allIngredients.append(ingredient)
        }
        let total = ingredientsInMeal.map({$0.waterData * Double($0.quantity!)}).reduce(0, +)
        day.setData([mealType + "_total" : total], options: SetOptions.merge())
        day.setData([mealType : allIngredients], options: SetOptions.merge())
        if let destination = self.navigationController?.viewControllers[1] {
            self.navigationController?.popToViewController(destination, animated: true)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchText == ""){
            displayedIngredients = ingredientsFromDatabase
        } else {
            displayedIngredients = ingredientsFromDatabase.filter({$0.name.lowercased().contains(searchText.lowercased())})
        }
        self.tableView.reloadData()
    }
}
