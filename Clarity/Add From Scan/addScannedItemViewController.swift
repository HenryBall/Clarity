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
    
    @IBOutlet weak var bannerImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    var invertedIndex : CollectionReference!
    var ingredientDB : CollectionReference!
    var mealType : String!
    var matchedWaterTotal = 0.0
    var ingredientsList : JSON!
    var refsInMeal = [DocumentReference]()
    var matchedRefs = [DocumentReference]()
    var ingredientsInMeal = [Ingredient]()
    var matchedIngredients = [Ingredient]()
    
    // NLP stuff
    let tagger = NSLinguisticTagger(tagSchemes:[.tokenType, .language, .lexicalClass, .nameType, .lemma], options: 0)
    let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        hideKeyboard()
        setBannerImage()
        getFoodInMeal()
        ingredientDB = db.collection("water-footprint-data")
        invertedIndex = db.collection("water-data-inverted-index")
        doTextProcessing(text: ingredientsList)
    }
    
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
    
    @IBAction func backTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func doTextProcessing (text: JSON) {
        if text != JSON.null{
            let ingredientsList = text.string!.lowercased().components(separatedBy: ", ")
            for ingredient in ingredientsList {
                matchIngredient (name: ingredient)
            }
        }else{
            print("Sorry, the ingredients for this item are unavailable")
        }
    }
    
    func getFoodInMeal() {
        let today = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .long
        formatter.string(from: today)
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
    
    @IBAction func saveTapped(_ sender: UIButton) {
        let refsToPush = matchedRefs + refsInMeal
        day.setData([self.mealType: refsToPush], options: SetOptions.merge())
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
                    
                    for (_, num) in termScores { sum += num }
                    
                    if (sum > maxScore) {
                        maxScore = sum
                        matchedItem = id
                    }
                }
                let matchedRef = self.ingredientDB.document(matchedItem!)
                self.matchedRefs.append(matchedRef)
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchedRefs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scannedItemCell") as! scannedItemCell
        let curRef = matchedRefs[indexPath.row]
        curRef.getDocument { (document, error) in
            if(document?.exists)!{
                let name = document?.documentID as! String
                let imagePath = "food-icons/" + name.uppercased() + ".jpg"
                let imageRef = storage.reference().child(imagePath)
                cell.name.text = name
                cell.icon.sd_setImage(with: imageRef, placeholderImage: #imageLiteral(resourceName: "Food"))
            } else {
                print("No food exists for this meal")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let curRef = matchedRefs[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        matchedRefs.remove(at: indexPath.row)
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
