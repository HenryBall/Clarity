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

class addScannedItemViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    /* Banner and TableView outlets */
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var itemName: UITextField!
    
    /* Class Globals */
    var mealType : String!
    var ingredientsList : JSON!
    var invertedIndex : CollectionReference!
    var ingredientDB : CollectionReference!
    var ingredientsInMeal = [Ingredient]()
    var matchedIngredients = [Ingredient]()
    var displayedIngredients = [Ingredient]()
    
    /* Tagger and options for NLP functions */
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        setBannerImage()
        ingredientDB = db.collection("water-footprint-data")
        invertedIndex = db.collection("water-data-inverted-index")
        doTextProcessing(text: ingredientsList)
    }
    
    /*
     - Set the banner based on the meal type
    */
    func setBannerImage() {
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
    
    /*
     - Pop the current ViewController sending us back to the MealViewController
    */
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /*
     - Filter the matched refs, only taking those selected in the TableView
    */
    func getMatchedRefsToPush() -> [DocumentReference] {
        var matched = [DocumentReference]()
        for ing in matchedIngredients{
            let ref = db.document("water-footprint-data/" + ing.name.capitalized)
            matched.append(ref)
        }
        return matched
    }

    /*
     - Get the water total for the selected ingredients
     - Push the selected ingredients and total to Firestore
    */
    @IBAction func saveTapped(_ sender: UIButton) {
        if(itemName.text == ""){
            let alert = UIAlertController(title: "Oops!", message: "Please enter a name", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }else{
            let group = DispatchGroup()
            let matched = getMatchedRefsToPush()
            let refWithMostWater = matchedIngredients.max { $0.waterData < $1.waterData }
            let imageName = (refWithMostWater?.name)!
            let matchedWaterTotal = matchedIngredients.map({$0.waterData}).reduce(0, +)
        
            let ingredient = Ingredient(name: self.itemName.text!, type: "Scanned", waterData: matchedWaterTotal, description: "", servingSize: 1, category: nil, source: "", quantity: 1, ingredients: matched, imageName: imageName)
            ingredientsInMeal.append(ingredient)
        
            group.notify(queue: .main) {
                
                var foodInMeal = [[String : Any]]()
                var map = [String : Any]()
        
                for ing in self.ingredientsInMeal {
                    if(ing.type == "Database"){
                        let ref = db.document("water-footprint-data/" + ing.name.capitalized)
                        map = ["reference" : ref, "quantity" : ing.quantity ?? 1]
                    } else if(ing.type == "Scanned"){
                        map = ["name" : ing.name, "total" : ing.waterData, "ingredients": matched, "image": ing.imageName as Any, "quantity" : ing.quantity ?? 1, "type" : ing.type]
                    }else{
                        map = ["name" : ing.name, "total" : ing.waterData, "quantity" : ing.quantity ?? 1]
                    }
                    foodInMeal.append(map)
                }
                
                let total = self.ingredientsInMeal.map({$0.waterData}).reduce(0, +)
                day.setData([self.mealType + "_total" : total], options: SetOptions.merge())
                day.setData([self.mealType : foodInMeal], options: SetOptions.merge())
                
                if let destination = self.navigationController?.viewControllers[1] {
                    self.navigationController?.popToViewController(destination, animated: true)
                }
            }
        }
    }
    
    /*
     - Process the (JSON) ingredients received from Google Vision api
     - Call findCandidtaes on each chunk of text separated by commas
     */
    func doTextProcessing (text: JSON) {
        if text != JSON.null{
            let ingredientsList = text.string!.lowercased().components(separatedBy: ", ")
            for ingredient in ingredientsList {
                let strippedIngr = partOfSpeech(text: ingredient)
                findCandidates(ingredient: strippedIngr)
            }
        }else{
            print("Sorry, the ingredients for this item are unavailable")
        }
    }
    
    /*
     - Get the candidate matches from the invertedIndex
    */
    func findCandidates(ingredient: String) {
        let arr = tokenizeText(for: ingredient)
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
            self.findBestMatch(dic: dic)
        }
    }
    
    /*
     - Find the match whose term scores produce the highest sum
    */
    func findBestMatch(dic: Dictionary<String, DocumentSnapshot>) {
        var maxScore = 0.0
        var matchedItem : String!
        if !dic.isEmpty {
            for (id, snapshot) in dic {
                let termScores = snapshot.data()!["term_scores"] as! [String : Double]
                var sum = 0.0
                for (_, num) in termScores { sum += num }
                if (sum > maxScore) {
                    maxScore = sum
                    matchedItem = id
                }
            }
            
            let currentIngredient = self.ingredientDB.document(matchedItem!)
            currentIngredient.getDocument { (document, error) in
                if(document?.exists)!{
                    let current_ingredient = Ingredient(document: document!)
                    self.matchedIngredients.append(current_ingredient)
                    self.displayedIngredients = self.matchedIngredients
                    self.tableView.reloadData()
                } else {
                    print("No food exists for this meal")
                }
            }
        }
    }
    
    /*
     - Takes in a string and removes verbs
     */
    func partOfSpeech(text: String) -> String {
        tagger.string = text
        var outString = ""
        let range = NSRange(location: 0, length: text.utf16.count)
        if #available(iOS 11.0, *) {
            tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, _ in
                if let tag = tag {
                    let word = (text as NSString).substring(with: tokenRange)
                    if (tag.rawValue == "Verb") {
                        print("We don't want verbs")
                    } else {
                        outString = outString + word
                    }
                }
            }
            return outString
        } else {
            return outString
        }
    }
    
    /*
     - Split a string of words on spaces and return the corresponding array
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
            return arr
        }
    }
    
    /*
     - Set the hight of each TableView cell
    */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    /*
     - Set the number of rows in the TableView to be equal to the number of matched ingredients
    */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchedIngredients.count
    }
    
    /*
     - Set the ContentView of each cell
    */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scannedItemCell") as! scannedItemCell
        
        let ingredient = displayedIngredients[indexPath.row]
        
        cell.name.text = ingredient.name.capitalized
        cell.gallons.text = String(Int(ingredient.waterData))
        let imagePath = "food-icons/" + ingredient.name.uppercased() + ".jpg"
        let imageRef = storage.reference().child(imagePath)
        cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
        
        return cell
    }
    
    /*
     - Set the default state of each cell as selected
    */
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
    }
    
    /*
     - Set the value corresponding to the tapped cell as true
    */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ingredient = displayedIngredients[indexPath.row]
        matchedIngredients.append(ingredient)
    }
    
    /*
     - Set the value corresponding to the tapped cell as false
    */
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let ingredient = displayedIngredients[indexPath.row]
        
        if let index = matchedIngredients.index(where: { $0.name == ingredient.name }) {
            matchedIngredients.remove(at: index)
        }
    }
}
