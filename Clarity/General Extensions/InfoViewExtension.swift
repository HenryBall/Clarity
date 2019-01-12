//
//  UIViewControllerExtension.swift
//  Clarity
//
//  Created by henry on 10/20/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension UIViewController {
    
    /* Extensions for setting up info view just to hide the ugly code
     -- used in HomeViewController and MealViewControllerDelegateExtension
    */
    func getCategoryArr(category: String) -> [Ingredient] {
        switch(category){
        case "protein":
            return proteins
        case "fruit":
            return fruits
        case "vegetables":
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
    
    /**
     Calculates and returns an integer representing how an item's water usage compares against every other item in the same category.
     - Parameter category: Current item's category, since a guard let is used where it's called, cannot be nil in this function
     - Parameter name: Current item's name */
    func getPercentile(category: String, name: String) -> Int {
            let categoryArr = getCategoryArr(category: category)
            let sorted = categoryArr.sorted(by: {$0.waterData < $1.waterData})

            if(sorted.count != 0){
                let index = sorted.index(where: {$0.name == name})!
                let percentile = (Double(index)/Double(sorted.count)) * 100.0
                return Int(percentile)
            }
        return 0
    }
    
    /**
     Sets the rating view (left): image and label
     - Parameter percentile: Current item's percentile in it's category
     - Parameter view: Image of green, yellow or orange circle depending on value
     - Parameter label: "good, fair or bad" overall rating */
    func setRating(percentile: Int, view: UIImageView, label: UILabel) {
        var boldText = "fair"
        
        if percentile >= 75 {
            view.layer.backgroundColor = UIColor.ratingColors.badRating.cgColor
            view.image = UIImage(named: "bad")
            boldText = "poor"
        } else if percentile >= 25 && percentile < 75{
            view.layer.backgroundColor = UIColor.ratingColors.fairRating.cgColor
            view.image = UIImage(named: "fair")
        } else {
            view.layer.backgroundColor = UIColor.ratingColors.goodRating.cgColor
            view.image = UIImage(named: "good")
            boldText  = "good"
        }
        
        let attributedString = NSMutableAttributedString(string: "")
        let attrs: [NSAttributedStringKey: Any] = [.font: UIFont(name: "AvenirNext-Bold", size: 12)!]
        let boldString = NSMutableAttributedString(string: boldText, attributes: attrs)
        attributedString.append(boldString)
        attributedString.append(NSMutableAttributedString(string: "\noverall rating"))
        label.attributedText = attributedString
    }
}
