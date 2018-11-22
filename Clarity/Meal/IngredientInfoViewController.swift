//
//  IngredientInfoViewController.swift
//  Clarity
//
//  Created by Celine Pena on 11/20/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import UIKit
import Firebase

class IngredientInfoViewController: UIViewController {

    @IBOutlet weak var name                 : UILabel!
    @IBOutlet weak var gallonsPerServing    : UILabel!
    @IBOutlet weak var servingSize          : UILabel!
    @IBOutlet weak var percentile           : UILabel!
    @IBOutlet weak var source               : UITextView!
    
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var ratingImage: UIImageView!
    var ingredientToShow                    : Ingredient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.closeScreen(_:)))
        background.addGestureRecognizer(tap)
        setupView()
    }
    
    func setupView(){
        //Ingredient Name
        name.text = ingredientToShow.name.capitalized
        
        //Overall Rating (left)
        guard let ingredientCategory = ingredientToShow.category else {
            print("category is nil")
            return
        }
        
        let ingPercentile = calcPercentile(ingredient: ingredientToShow)
        setRating(percentile: ingPercentile, view: ratingImage, label: rating)
        
        //Percentile (Middle)
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        let suffixAdded = formatter.string(from: NSNumber(value: ingPercentile))
        percentile.text = suffixAdded! + " percentile of " + (ingredientCategory)
        
        
        //Serving size (Right)
        guard let ingredientServingSize = ingredientToShow.servingSize else {
            print("serving size is nil")
            return
        }
        
        servingSize.text = "serving size: " + String(Int(ingredientServingSize)) + " oz"
        getPortionPreference(servingSize: ingredientServingSize, ingredient: ingredientToShow)
        
        //Source label
        guard let sourceURL = ingredientToShow.source else {
            print("source is nil")
            return
        }
        source.text = "Source: \n" + sourceURL
    }
    
    func getPortionPreference(servingSize: Double, ingredient: Ingredient) {
        guard let userID = UserDefaults.standard.string(forKey: "user_id") else {
            print("user ID cannot be found in user defaults")
            return
        }
        let group = DispatchGroup()
        group.enter()
        var portion = "Per Serving"
        let userRef = Firestore.firestore().collection("users").document(userID)
        userRef.getDocument { (document, error) in
            if let document = document {
                if let portionSettings = document.data()?["portion"] as? String {
                    if(portionSettings == "Per Ounce"){
                        portion = "Per Ounce"
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            self.setPortionPreference(servingSize: servingSize, portion: portion, ingredient: ingredient)
        }
    }
    
    func setPortionPreference(servingSize: Double, portion: String, ingredient: Ingredient){
        //Gallons of water label
        var boldText = String(Int(ingredientToShow.waterData)) + " gallons"
        var portionText = " of water per " + String(Int(servingSize)) + " oz"
        let attributedString = NSMutableAttributedString(string: "")
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont(name: "AvenirNext-Bold", size: 14)!]
        let boldString = NSMutableAttributedString(string: boldText, attributes: attrs)
        
        if(portion == "Per Ounce"){
            boldText = String(Int(ingredient.waterData/servingSize)) + " gallons"
            portionText = " of water per 1 oz"
        }
        attributedString.append(boldString)
        attributedString.append(NSMutableAttributedString(string: portionText))
        gallonsPerServing.attributedText = attributedString
    }
    @objc func closeScreen(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
}
