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
    let today = Date()
    let formatter = DateFormatter()
    //var foodInMeal = [Food]()
    var mealType: String!
    var foodInMeal = [[String : Any]]()
    var currentTotal = 0.0
    
    // NLP stuffs
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    var ingredientsText: JSON = []
    var day: DocumentReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
        day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(formatter.string(from: today))
        
        queryFoodInMeal()
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
    
    ///Query the items that exist in ""-meals. When we select an item, they will be added to this array
    func queryFoodInMeal(){
        let today = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
        
        day.getDocument { (document, error) in
            if(document?.exists)!{
                if(document?.data()?.keys.contains(self.mealType + "-meals"))!{
                    self.foodInMeal = document?.data()![self.mealType + "-meals"] as! [[String : Any]]
                }
                
                if(document?.data()?.keys.contains(self.mealType + "_total"))!{
                    self.currentTotal = document?.data()![self.mealType + "_total"] as! Double
                }
            } else {
                print("No food exists for this meal")
            }
        }
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
    
    func searchItem(number: String, name: String){
        let params : [String : String] = ["api_key" : API_KEY, "format": "JSON", "type": "b", "ndbno" : number]
        Alamofire.request(report_url, method: .get, parameters: params).responseJSON{
            response in
            if response.result.isSuccess{
                let itemJSON : JSON = JSON(response.result.value!)
                
                let totalGallons = self.compareIngredients(text: itemJSON["report"]["food"]["ing"]["desc"])
                
                var map = [String : Any]()
                map = ["name" : name, "total" : totalGallons]
                self.foodInMeal.append(map)
        
                self.currentTotal = self.currentTotal + totalGallons
                
            } else {
                print("Request: \(String(describing: response.request))")
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        searchItem(number: searchedProducts[indexPath.row].ndbno, name: searchedProducts[indexPath.row].name)
        //let currentIngredient = searchedProducts[indexPath.row]
        //let cell = tableView.dequeueReusableCell(withIdentifier: "addDatabaseIngredientCell") as! addDatabaseIngredientCell
        //print(cell.count.text)
        //if let count = Int(cell.count.text!){
        //if(count > 1){
        //for i in 0 ... count{
        //  ingredientsInMeal.append(currentIngredient)
        //}
        //}else{
        //ingredientsInMeal.append(currentIngredient)
        //}
        //}
       
        
       // self.navigationController?.popViewController(animated: true)
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
        day.setData([self.mealType + "-meals" : self.foodInMeal], options: SetOptions.merge())
        day.setData([self.mealType + "_total" : self.currentTotal], options: SetOptions.merge())
        if let destination = self.navigationController?.viewControllers[1] {
            self.navigationController?.popToViewController(destination, animated: true)
        }
    }
}
