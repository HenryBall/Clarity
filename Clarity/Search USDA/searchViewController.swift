//
//  searchViewController.swift
//  Clarity
//
//  Created by Celine Pena on 5/20/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Foundation
import Firebase

class searchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    let search_url = "https://api.nal.usda.gov/ndb/search/"
    let report_url = "https://api.nal.usda.gov/ndb/reports/"
    let API_KEY = "TGfnBgw7WgOWmRSo24XcFgtaoFbhODXG7KQZzVk4"
    
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var searchedProducts = [SearchProduct]()
    var ingredientsInMeal = [Ingredient]()
    let today = Date()
    let formatter = DateFormatter()
    var mealType: String!
    
    // NLP stuffs
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    var ingredientsText: JSON = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
    
        setBanner()
    }
    
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

    @IBAction func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func compareIngredients(text: JSON) -> Double {
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
            
           return matchedIngredients.map({$0.waterData}).reduce(0, +)
            
        }else{
            print("Sorry the ingredients for this item are unavailable")
            return 0.0
        }
    }
    
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
    
    func addItemToList(number: String, name: String, quantity: Int){
        let params : [String : String] = ["api_key" : API_KEY, "format": "JSON", "type": "b", "ndbno" : number]
        Alamofire.request(report_url, method: .get, parameters: params).responseJSON{
            response in
            if response.result.isSuccess{
                let itemJSON : JSON = JSON(response.result.value!)
                
                let totalGallons = self.compareIngredients(text: itemJSON["report"]["food"]["ing"]["desc"]) * Double(quantity)
                
                let currentIngredient = Ingredient(name: name, waterData: totalGallons, description: "", servingSize: 1, category: nil, source: "", quantity: quantity, reference: nil)
                self.ingredientsInMeal.append(currentIngredient)
                
            } else {
                print("Request: \(String(describing: response.request))")
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    //Set up parameters based on search bar value
    func searchProducts(searchText: String){
        let params : [String : String] = ["api_key" : API_KEY, "q" : searchText, "format": "JSON", "sort": "r"]
        getSearchData(url: search_url, parameters: params)
    }
    
    //Make Call to API to search for Item
    func getSearchData(url: String, parameters: [String: String]){
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON{
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
    
    @IBAction func doneTapped(_ sender: UIButton) {
        var foodInMeal = [[String : Any]]()
        var map = [String : Any]()
        
        for ing in ingredientsInMeal {
            if(ing.source != ""){
                let ref = db.document("water-footprint-data/" + ing.name.capitalized)
                map = ["reference" : ref, "quantity" : ing.quantity ?? 1]
            } else {
                map = ["name" : ing.name, "total" : ing.waterData, "quantity" : ing.quantity ?? 1]
            }
            foodInMeal.append(map)
        }
        
        let total = ingredientsInMeal.map({$0.waterData}).reduce(0, +)
        day.setData([self.mealType + "_total" : total], options: SetOptions.merge())
        day.setData([self.mealType : foodInMeal], options: SetOptions.merge())
        
        if let destination = self.navigationController?.viewControllers[1] {
            self.navigationController?.popToViewController(destination, animated: true)
        }
    }
}
