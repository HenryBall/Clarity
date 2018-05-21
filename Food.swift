//
//  Food.swift
//  Clarity
//
//  Created by Celine Pena on 5/20/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import Foundation
import Firebase

class Food {
    
    var name : String
    //var ingredients = [Ingredient]()
    var totalGallons: Double
    
    init(name: String, totalGallons: Double) {
        self.name = name
        self.totalGallons = totalGallons
        //self.ingredients = ingredients
    }
    
//    init(document: DocumentSnapshot){
//        self.name = document.data()!["name"] as! String
//        self.ingredients = document.data()!["ingredients"] as! Array
//    
//    }
}
