//
//  firebaseHelper.swift
//  Clarity
//
//  Created by Henry Ball on 5/31/18.
//  Copyright © 2018 Robert. All rights reserved.
//

import UIKit
import Firebase
import Foundation

class firebaseHelper {
    let db = Firestore.firestore()
    
    static func getTotalForDay(day: DocumentReference, group: DispatchGroup) -> Double {
        
        var total = 0.0
        
        day.getDocument { (document, error) in
            if(document?.exists)!{
                let breakfastRef = document?.data()!["breakfast"] as! [DocumentReference]
                for ref in breakfastRef {
                    ref.getDocument { (doc, error) in
                        if let doc = doc, doc.exists {
                            total = total + (doc.data()!["gallons_water"] as! Double)
                        } else {
                            print("Document does not exist")
                        }
                    }
                }
                group.leave()
            }else{
                print("Error")
            }
        }
        return total
    }
}
