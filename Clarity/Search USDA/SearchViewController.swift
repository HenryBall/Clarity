//
//  searchViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/20/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Foundation
import Firebase

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    /* IB Outlets */
    @IBOutlet weak var bannerImage  : UIImageView!
    @IBOutlet weak var searchBar    : UISearchBar!
    @IBOutlet weak var tableView    : UITableView!
    @IBOutlet weak var mealLabel    : UILabel!
    
    /* Class Globals */
    var searchedProducts            = [SearchProduct]()
    var ingredientsInMeal           = [Ingredient]()
    var addedIngredients            = [Ingredient]()
    var mealType                    : String!
    
    let search_url                  = "https://api.nal.usda.gov/ndb/search/"
    let report_url                  = "https://api.nal.usda.gov/ndb/reports/"
    let API_KEY                     = "TGfnBgw7WgOWmRSo24XcFgtaoFbhODXG7KQZzVk4"
    
    // NLP stuffs
    let tagger                      = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options                     : NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        let today = Date()
        formatter.string(from: today)
    
        setBannerImage(mealType: mealType, imageView: bannerImage, label: mealLabel)
    }
    
    /**
     Called when the user selects a row. This function makes a call to the USDA API to get the ingredients for the selected item (returned as JSON).
     Once the JSON has been recieved, calls compareIngredients to return the list of ingredients that match ingredients for which we have data for.
     Adds this item to the ingredientsInMeal() array.
     - Parameter number: "ndbno" number supplied (needed) to query the USDA database (specific to each item)
     - Parameter name: name of the selected food
     - Parameter quantity: Quantity the user would like to add to the database
     */
    func addItemToList(number: String, name: String, quantity: Int){
        let params : [String : String] = ["api_key" : API_KEY, "format": "JSON", "type": "b", "ndbno" : number]
        Alamofire.request(report_url, method: .get, parameters: params).responseJSON{
            response in
            if response.result.isSuccess{
                let itemJSON : JSON = JSON(response.result.value!)
                
                let matchedIngredients = self.compareIngredients(text: itemJSON["report"]["food"]["ing"]["desc"])
                let totalGallons = matchedIngredients.map({$0.waterData}).reduce(0, +) * Double(quantity)
                let refWithMostWater = matchedIngredients.max { $0.waterData < $1.waterData }
                let imageName = (refWithMostWater?.category)!
                
                let ingredientRefs = self.getMatchedRefsToPush(matchedIngredients: matchedIngredients)
                
                let currentIngredient = Ingredient(name: name, type: "USDA", waterData: totalGallons, description: "", servingSize: 1, category: nil, source: "", quantity: quantity, ingredients: ingredientRefs, imageName: imageName)
                self.ingredientsInMeal.append(currentIngredient)
                self.addedIngredients.append(currentIngredient)
                
            } else {
                print("Request: \(String(describing: response.request))")
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    /**
     Compares ingredients in the selected food against ingredients from database.
     - Parameter text: JSON of ingredients in this food
     - Returns: Array of Ingredients for which we have water footprint data for. If none exist, returns an empty array.
     - Note: This comparison is based on substrings so it can probably be improved in the future.
     */
    func compareIngredients(text: JSON) -> [Ingredient] {
        var ingredientsList: [String]
        var matchedIngredients = [Ingredient]()
        
        if text != JSON.null{
            let str = text.string!
            ingredientsList = tokenizeText(for: str)
            
            if(ingredientsFromDatabase.count > 0 && ingredientsList.count > 0){
                for i in 0 ... ingredientsFromDatabase.count-1{
                    for j in 0 ... ingredientsList.count-1 where
                        ingredientsList[j].uppercased().contains(ingredientsFromDatabase[i].name){
                        if(!matchedIngredients.contains(where: { $0.name == ingredientsFromDatabase[i].name })){
                            matchedIngredients.append(ingredientsFromDatabase[i])
                        }
                    }
                }
            }
           return matchedIngredients
            
        }else{
            print("Sorry the ingredients for this item are unavailable")
            return []
        }
    }
    
    /**
     Splits ingredients list into single words
     - Returns: Array of single words
     */
    func tokenizeText(for text: String) -> [String] {
        var arr = [String]()
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)
        if #available(iOS 11.0, *) {
            tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { tag, tokenRange, stop in
                let word = (text as NSString).substring(with: tokenRange)
                arr.append(word)
            }
            return arr
        } else {
            return []
        }
    }
    
    /**
     Creates reference for each ingredient, appends them to "matched" array
     - Parameter matchedIngredients: Array of Ingredients for a food item
     - Returns: Array of ingredient references to be pushed to database
     */
    func getMatchedRefsToPush(matchedIngredients: [Ingredient]) -> [DocumentReference] {
        var matched = [DocumentReference]()
        for ing in matchedIngredients{
            let ref = db.document("water-footprint-data/" + ing.name.capitalized)
            matched.append(ref)
        }
        return matched
    }
    
    //Make Call to API to search for Item
    func searchProducts(searchText: String){
        let params : [String : String] = ["api_key" : API_KEY, "q" : searchText, "format": "JSON", "sort": "r"]
        
        Alamofire.request(search_url, method: .get, parameters: params).responseJSON{
            response in
            if response.result.isSuccess{
                let searchJSON : JSON = JSON(response.result.value!)
                self.updateSearchData(json: searchJSON)
            } else {
                print("Request: \(String(describing: response.request))")
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    //Parse Data to set searchCells with the correct data
    func updateSearchData(json: JSON){
        let itemDict = json["list"]["item"]
        searchedProducts.removeAll()
        for (_, item) in itemDict{
            var itemName = item["name"].string!
            
            // Remove UPC from name
            let upc_range = itemName.range(of: ", UPC") //{
            if let upc = upc_range?.lowerBound {
                itemName.removeSubrange(itemName.index(after: upc)..<itemName.endIndex)
            }
            // Remove GTIN from name
            let gtin_range = itemName.range(of: ", GTIN")
            if let gtin = gtin_range?.lowerBound{
                itemName.removeSubrange(itemName.index(after: gtin)..<itemName.endIndex)
            }
            
            if itemName.last == ","{
                itemName.removeLast()
            }
            
            let itemNdbno = item["ndbno"].string!
            searchedProducts.append(SearchProduct(name: itemName, ndbno: itemNdbno))
        }
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchProducts(searchText: searchText)
        self.tableView.reloadData()
    }
    
    func setRecent() {
        let userRef = db.collection("users").document(defaults.string(forKey: "user_id")!)
        var pushToDatabase = [[String : Any]]()
        
        if(self.addedIngredients.count == 1){
            for item in recent {
                if (item["index"] as? Int == 0){
                    if let itemRef = item["reference"] as? DocumentReference {
                        pushToDatabase.append(["index": 1, "reference": itemRef])
                    } else {
                        pushToDatabase.append(["index": 1, "image": item["image"]!, "name": item["name"]!, "total": item["total"]!])
                    }
                }
            }
        }
        var index = 0
        if self.addedIngredients.count > 1 {
            index = addedIngredients.count-2
            let ing = self.addedIngredients[index+1]
            pushToDatabase.append(["index": 1, "image": ing.imageName as Any, "name": ing.name.capitalized, "total": ing.waterData])
        }
        
        let ing2 = self.addedIngredients[index]
        pushToDatabase.append(["index": 0, "image": ing2.imageName as Any, "name": ing2.name.capitalized, "total": ing2.waterData])
        pushToDatabase.reverse()
        
        userRef.setData(["recent" : pushToDatabase], options: SetOptions.merge())
    }
    
    //------------------------------------------ IBActions --------------------------------------------------
    
    /**
     When the user presses the "<" button, returns to the home screen
     - Parameter sender: "<" back button */
    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /**
     When the user presses the "add" button, updates the ingredients in the database and returns to HomeViewController
     - Parameter sender: "add" button on top right */
    @IBAction func doneTapped(_ sender: UIButton) {
        var foodInMeal = [[String : Any]]()
        var map = [String : Any]()
        
        for ing in ingredientsInMeal {
            if(ing.type == "Database"){
                let ref = db.document("water-footprint-data/" + ing.name.capitalized)
                map = ["reference" : ref, "quantity" : ing.quantity ?? 1]
            }else {
                map = ["name" : ing.name, "total" : ing.waterData, "ingredients": ing.ingredients as Any, "image": ing.imageName as Any, "quantity" : ing.quantity ?? 1, "type" : ing.type]
            }
            foodInMeal.append(map)
        }
        
        let total = ingredientsInMeal.map({$0.waterData}).reduce(0, +)
        day.setData([self.mealType + "_total" : total], options: SetOptions.merge())
        day.setData([self.mealType : foodInMeal], options: SetOptions.merge())
        setRecent()
        
        if let destination = self.navigationController?.viewControllers[1] {
            self.navigationController?.popToViewController(destination, animated: true)
        }
    }
}
