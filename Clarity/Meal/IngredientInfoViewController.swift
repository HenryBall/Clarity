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

    //IBOutlet
    @IBOutlet weak var name                 : UILabel!
    @IBOutlet weak var gallonsPerServing    : UILabel!
    @IBOutlet weak var servingSize          : UILabel!
    @IBOutlet weak var percentile           : UILabel!
    @IBOutlet weak var rating               : UILabel!
    @IBOutlet weak var ratingImage          : UIImageView!
    @IBOutlet weak var source               : UITextView!
    @IBOutlet weak var background           : UIView!
    
    //Class Globals
    var ingredientToShow                    : Ingredient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.closeScreen(_:)))
        background.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //TO DO: Show error screen
        guard ingredientToShow != nil else {
            print("Ingredient is nil")
            return
        }
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
        
        let ingPercentile = getPercentile(category: ingredientCategory, name: ingredientToShow.name)
        setRating(percentile: ingPercentile, view: ratingImage, label: rating)
    
        //Percentile (Middle)
        if(ingPercentile < 50){
            percentile.text = "Uses less water than " + String(100-ingPercentile) + "% of other " + ingredientCategory
        } else {
            percentile.text = "Uses more water than " + String(ingPercentile) + "% of other " + ingredientCategory
        }

        //Serving size (Right)
        guard let ingredientServingSize = ingredientToShow.servingSize else {
            print("serving size is nil")
            return
        }
        
        servingSize.text = "serving size: " + String(Int(ingredientServingSize)) + " oz."
        setPortionPreference(servingSize: ingredientServingSize)
        
        //Source label
        guard let sourceURL = ingredientToShow.source else {
            print("source is nil")
            return
        }
        source.text = "Source: \n" + sourceURL
    }

    /**
     Sets the UI based on whichever portion preference the user has set,
     either displayed as per oz. or per serving
     - Parameter servingSize: Double describing the serving size in oz., since guard let is used earlier in the code, cannot be nil
     - Parameter portion: either "Per Ounce" or "Per Serving", determined by user's preference saved to the database */
    func setPortionPreference(servingSize: Double){
        if (portionPref == "Per Ounce") {
            let galStr = Int(ingredientToShow.waterData/servingSize) > 1 ? " gallons" : " gallon"
            gallonsPerServing.text = String(Int(ingredientToShow.waterData/servingSize)) + galStr + " of water per oz."
        } else {
            let galStr = Int(ingredientToShow.waterData) > 1 ? " gallons" : " gallon"
            let ozStr = Int(servingSize) > 1 ? (" of water per " + String(Int(servingSize)) + " oz.") : " of water per oz."
            gallonsPerServing.text = String(Int(ingredientToShow.waterData)) + galStr + ozStr
        }
    }
    
    ///Closes the info view. Triggered by tapping on the background view
    @objc func closeScreen(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
}
