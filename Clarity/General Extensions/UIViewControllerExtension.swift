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
    
    func setColor(category: String) -> UIColor {
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
        } else {
            returnColor = UIColor.clear
        }
        return returnColor
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
        case "other":
            return other
        default:
            /* show error */
            print("err")
            return []
        }
    }
}
