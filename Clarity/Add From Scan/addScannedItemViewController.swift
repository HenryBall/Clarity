//
//  addScannedItemViewController.swift
//  Clarity
//
//  Created by Celine Pena on 6/11/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import SwiftyJSON
import Firebase

class addScannedItemViewController: UIViewController {
    
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var totalGallons: UILabel!
    @IBOutlet weak var itemNameField: UITextField!
    
    var invertedIndex : CollectionReference!
    var ingredientDB : CollectionReference!
    var mealType : String!
    var thisFoodTotal = 0.0
    var currentTotal = 0.0
    var ingredientsList : JSON!
    var foodInMeal = [[String : Any]]()
    var matchedIngredients = [Ingredient]()
    
    // NLP stuff
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboard()
        setBannerImage()
        queryFoodInMeal()

        ingredientDB = db.collection("water-footprint-data")
        invertedIndex = db.collection("water-data-inverted-index")
        
        doTextProcessing(text: ingredientsList)
    }
    
    func setBannerImage(){
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
            print("error setting banner image")
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func doTextProcessing (text: JSON) {
        if text != JSON.null{
            let ingredientsList = text.string!.lowercased().components(separatedBy: ", ")
            for ingredient in ingredientsList {
                //ingredientsList.append(ingredient)
                matchIngredient (name: ingredient)
            }
        }else{
            print("Sorry, the ingredients for this item are unavailable")
        }
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
    
    @IBAction func saveTapped(_ sender: UIButton) {
        var map = [String : Any]()
        let name = itemNameField.text
        map = ["name" : name, "total" : thisFoodTotal]
        self.foodInMeal.append(map)
        self.currentTotal = self.currentTotal + thisFoodTotal
        
        day.setData([self.mealType + "-meals" : self.foodInMeal], options: SetOptions.merge())
        day.setData([self.mealType + "_total" : self.currentTotal], options: SetOptions.merge())
        
        if let destination = self.navigationController?.viewControllers[1] {
            self.navigationController?.popToViewController(destination, animated: true)
        }
    }
    
    func matchIngredient (name: String) {
        let arr = tokenizeText (for: name)
        var dic : Dictionary<String, DocumentSnapshot> = [String : DocumentSnapshot]()
        
        let group = DispatchGroup()
        
        for word in arr {
            group.enter()
            invertedIndex.document(word).getDocument { (document, error) in
                if let document = document, document.exists {
                    let candidentIngredients = document.get("documents") as! [DocumentReference]
                    for ingredient in candidentIngredients {
                        group.enter()
                        ingredient.getDocument(completion: { (doc, err) in
                            dic[ingredient.documentID] = doc
                            group.leave()
                        })
                    }
                } else {
                    print("Document does not exist")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            var maxScore = 0.0
            var matchedItem : String!
            
            if !dic.isEmpty {
                for (id, snapshot) in dic {
                    
                    let termScores = snapshot.data()!["term_scores"] as! [String : Double]
                    var sum = 0.0
                    
                    for (_, num) in termScores {
                        sum += num
                    }
                    
                    if (sum > maxScore) {
                        maxScore = sum
                        matchedItem = id
                    }
                }
                
                var water = 0.0
                
                let matchedRef = self.ingredientDB.document(matchedItem!)
                matchedRef.getDocument(completion: { (doc, err) in
                    water = doc?.data()!["gallons_water"] as! Double
                    print(doc?.documentID)
                    self.thisFoodTotal = self.thisFoodTotal + water
                    self.totalGallons.text = String(Int(self.thisFoodTotal))
                })
            }
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
}
