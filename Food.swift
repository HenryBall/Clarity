//
//  Food.swift
//  Clarity
//
//  Created by Celine Pena on 5/20/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import Foundation
import Firebase

class Food {
    
    var name : String?
    var totalGallons: Double
    var quantity : Int?
    var reference : DocumentReference?
    
    init(name: String?, totalGallons: Double, quantity: Int?, reference: DocumentReference?) {
        self.name = name
        self.totalGallons = totalGallons
        self.quantity = quantity
        self.reference = reference
    }
    
    init(document: DocumentSnapshot){
        self.name = document.data()!["name"] as? String
        self.totalGallons = document.data()!["total"] as! Double
        self.quantity = document.data()!["quantity"] as? Int
        self.reference = document.data()!["reference"] as? DocumentReference
    }
}
