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
    
    /*func setColor(category: String) -> UIColor {
        let returnColor: UIColor
        if category == "fruit" {
            returnColor = orange
        } else if category == "vegetable" {
            returnColor = green
        } else if category == "protein" {
            returnColor = darkBlue
        } else if category == "drinks" {
            returnColor = blue
        } else if category == "dairy" {
            returnColor = yellow
        } else if category == "grains" {
            returnColor = brown
        } else {
            returnColor = purp
        }
        return returnColor
    }*/
    
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
    
    func setRating(percentile: Int, view: UIView, label: UILabel) {
        if percentile >= 75 {
            view.layer.borderColor = green.cgColor
            label.textColor = green
            label.text = "good"
        } else if 25 <= percentile && 75 > percentile {
            view.layer.borderColor = yellow.cgColor
            label.textColor = yellow
            label.text = "fair"
        } else {
            view.layer.borderColor = orange.cgColor
            label.textColor = orange
            label.text = "poor"
        }
    }
}
