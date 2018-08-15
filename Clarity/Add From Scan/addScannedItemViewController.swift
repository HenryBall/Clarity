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
    
    /* Class Globals */
    var mealType : String!
    var ingredientsList : JSON!
    var invertedIndex : CollectionReference!
    var ingredientDB : CollectionReference!
    var matchedWaterTotal = 0.0
    var currentWaterTotal = 0.0
    var refsInMeal = [DocumentReference]()
    var matchedRefs = [DocumentReference: Bool]()
    
    /* Tagger and options for NLP functions */
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        hideKeyboard()
        setBannerImage()
        getRefsInMeal()
        getWaterTotalForMeal()
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
     - Get the current foods in the selected meal
    */
    func getRefsInMeal() {
        day.getDocument { (document, error) in
            if(document?.exists)!{
                if(document?.data()?.keys.contains(self.mealType))!{
                    self.refsInMeal = document?.data()![self.mealType] as! [DocumentReference]
                }
            } else {
                print("No food exists for this meal")
            }
        }
    }
    
    /*
     - Get the current water total for the selected meal
    */
    func getWaterTotalForMeal() {
        day.getDocument { (document, error) in
            if(document?.exists)!{
                if(document?.data()?.keys.contains(self.mealType))!{
                    self.currentWaterTotal = document?.data()![self.mealType + "_total"] as! Double
                }
            } else {
                print("No total exists for this meal")
            }
        }
    }
    
    /*
     - Filter the matched refs, only taking those selected in the TableView
    */
    func getMatchedRefsToPush() -> [DocumentReference] {
        var matched = [DocumentReference]()
        for (key, val) in matchedRefs {
            if val == true {
                matched.append(key)
            }
        }
        return matched
    }

    /*
     - Get the water total for the selected ingredients
     - Push the selected ingredients and total to Firestore
    */
    @IBAction func saveTapped(_ sender: UIButton) {
        let group = DispatchGroup()
        let matched = getMatchedRefsToPush()
        for ref in matched {
            group.enter()
            ref.getDocument { (document, error) in
                group.leave()
                if(document?.exists)!{
                    self.matchedWaterTotal += document?.data()!["gallons_water"] as! Double
                } else {
                    print("Document does not exist")
                }
            }
        }
        group.notify(queue: .main) {
            let refsToPush = matched + self.refsInMeal
            let waterTotalToPush = self.matchedWaterTotal + self.currentWaterTotal
            day.setData([self.mealType: refsToPush], options: SetOptions.merge())
            day.setData([self.mealType + "_total": waterTotalToPush], options: SetOptions.merge())
            if let destination = self.navigationController?.viewControllers[1] {
                self.navigationController?.popToViewController(destination, animated: true)
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
                findCandidates(ingredient: ingredient)
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
            let matchedRef = self.ingredientDB.document(matchedItem!)
            self.matchedRefs[matchedRef] = true
            self.tableView.reloadData()
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
            return []
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
        return matchedRefs.count
    }
    
    /*
     - Set the ContentView of each cell
    */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scannedItemCell") as! scannedItemCell
        let matched = Array(self.matchedRefs.keys)
        let curRef = matched[indexPath.row]
        curRef.getDocument { (document, error) in
            if(document?.exists)!{
                let name = document?.documentID as! String
                let gallons = document?.data()!["gallons_water"] as! Double
                let imagePath = "food-icons/" + name.uppercased() + ".jpg"
                let imageRef = storage.reference().child(imagePath)
                cell.name.text = name
                cell.gallons.text = String(gallons)
                cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
            } else {
                print("No food exists for this meal")
            }
        }
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
        let matched = Array(self.matchedRefs.keys)
        let curRef = matched[indexPath.row]
        matchedRefs[curRef] = true
    }
    
    /*
     - Set the value corresponding to the tapped cell as false
    */
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let matched = Array(self.matchedRefs.keys)
        let curRef = matched[indexPath.row]
        matchedRefs[curRef] = false
    }
}
