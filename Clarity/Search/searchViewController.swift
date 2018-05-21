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

class searchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    let search_url = "https://api.nal.usda.gov/ndb/search/"
    let report_url = "https://api.nal.usda.gov/ndb/reports/"
    let API_KEY = "TGfnBgw7WgOWmRSo24XcFgtaoFbhODXG7KQZzVk4"
    
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var searchedProducts = [SearchProduct]()
    var foodInMeal = [Food]()
    var mealType: String!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
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
        cell.label.text = searchedProducts[indexPath.row].name
        return cell
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        searchItem(number: searchedProducts[indexPath.row].ndbno, name: searchedProducts[indexPath.row].name)
//    }
//
    func searchItem(number: String, name: String){
        //let destination = self.storyboard?.instantiateViewController(withIdentifier: "ProductViewController") as! ProductViewController
        let params : [String : String] = ["api_key" : API_KEY, "format": "JSON", "type": "b", "ndbno" : number]
        Alamofire.request(report_url, method: .get, parameters: params).responseJSON{
            response in
            if response.result.isSuccess{
                let itemJSON : JSON = JSON(response.result.value!)
                let item = Food(name: name, totalGallons: 60.0)
                self.foodInMeal.append(item)
                //destination.ingredientsText = itemJSON["report"]["food"]["ing"]["desc"]
                //destination.productName = name
                //self.show(destination, sender: nil)
                let today = Date()
                let formatter = DateFormatter()
                formatter.timeStyle = .none
                formatter.dateStyle = .long
                formatter.string(from: today)
                
                let day = db.collection("users").document(defaults.string(forKey: "user_id")!).collection("meals").document(formatter.string(from: today))
                
                //day.setData([self.mealType + "-meals" : self.foodInMeal])
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
        updateTable(searchText: searchText)
    }
    
    func updateTable(searchText: String){
        searchProducts(searchText: searchText)
        self.tableView.reloadData()
    }
    
}
