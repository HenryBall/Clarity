//
//  UIViewControllerExtension.swift
//  Clarity
//
//  Created by henry on 10/20/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    /* Extensions for setting up info view just to hide the ugly code
     -- used in HomeViewController and MealViewControllerDelegateExtension
    */
    func setCategory(category: String) -> String {
        let returnCategory: String
        if category == "vegetable" {
            returnCategory = "V"
        } else if category == "protein" {
            returnCategory = "P"
        } else if category == "drinks" {
            returnCategory = "B"
        } else if category == "fruit" {
            returnCategory = "F"
        } else if category == "dairy" {
            returnCategory = "D"
        } else {
            returnCategory = ""
        }
        return returnCategory
    }
    
    func getCategoryArr(category: String) -> [Ingredient] {
        switch(category){
        case "protein":
            return proteins
        case "fruit":
            return fruits
        case "vegetable":
            return vegetables
        case "dairy":
            return dairy
        case "drinks":
            return drinks
        case "grains":
            return grains
        case "other":
            return other
        default:
            /* show error */
            print("err")
            return []
        }
    }
    
    func calcPercentile(ingredient: Ingredient) -> Int {
        let categoryArr = getCategoryArr(category: ingredient.category!)
        let sorted = categoryArr.sorted(by: {$0.waterData > $1.waterData})
        let index = sorted.index(where: {$0.name == ingredient.name})!
        let percentile = (Double(index)/Double(sorted.count)) * 100.0
        return Int(percentile)
    }
    
    func setRating(percentile: Int, view: UIImageView, label: UILabel) {
        var boldText = "fair"
        
        if percentile >= 75 {
            view.layer.backgroundColor = UIColor(red: 177/255, green: 236/255, blue: 113/255, alpha: 1.0).cgColor
            view.image = UIImage(named: "good")
            boldText  = "good"
            
        } else if 25 <= percentile && 75 > percentile {
            view.layer.backgroundColor = yellow.cgColor
            view.image = UIImage(named: "fair")
        } else {
            view.layer.backgroundColor = orange.cgColor
            view.image = UIImage(named: "bad")
            boldText = "poor"
        }
        
        let attributedString = NSMutableAttributedString(string: "")
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont(name: "AvenirNext-Bold", size: 12)!]
        let boldString = NSMutableAttributedString(string: boldText, attributes: attrs)
        attributedString.append(boldString)
        attributedString.append(NSMutableAttributedString(string: "\noverall rating"))
        label.attributedText = attributedString
    }
}
