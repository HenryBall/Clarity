//
//  ingredient.swift
//  Clarity
//
//  Created by Celine Pena on 4/21/18.
//  Copyright © 2018 CMPS117. All rights reserved.
//

import Foundation
import Firebase

class Ingredient {
    var name : String
    var type : String
    var waterData : Double
    var description : String?
    var servingSize : Double?
    var category : String?
    var source : String?
    var quantity : Int?
    var ingredients : [DocumentReference]?
    var imageName : String?
    
    init(name: String, type: String, waterData: Double, description: String?, servingSize: Double?, category: String?, source: String?, quantity: Int?, ingredients: [DocumentReference]?, imageName: String?) {
        self.name = name
        self.type = type
        self.waterData = waterData
        self.description = description
        self.servingSize = servingSize
        self.category = category
        self.source = source
        self.quantity = quantity
        self.ingredients = ingredients
        self.imageName = imageName
    }
    
    init(document: DocumentSnapshot){
        self.name = document.documentID.uppercased()
        self.type = "Database"
        self.waterData = document.data()!["gallons_water"] as! Double
        self.description = document.data()!["description"] as? String
        self.servingSize = document.data()!["average_weight_oz"] as? Double
        self.category = document.data()!["category"] as? String
        self.source = document.data()!["source"] as? String
        self.quantity = 1
    }
}
