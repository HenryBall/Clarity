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
    
    static func getBreakfastTotalForDay(day: DocumentReference, completion: @escaping (Double, Error?) -> Void) {
        var total = 0.0
        let group = DispatchGroup()
        
        group.enter()
        day.getDocument { (document, error) in
            if (document?.exists)! {
                if let breakfastRef = document?.data()!["breakfast"] {
                    let refArray = breakfastRef as! [DocumentReference]
                    for ref in refArray {
                        group.enter()
                        ref.getDocument { (doc, error) in
                            if let doc = doc, doc.exists {
                                total = total + (doc.data()!["gallons_water"] as! Double)
                            } else {
                                print("Error")
                                //completion(0.0, ("Breakfast error" as! Error))
                            }
                            group.leave()
                        }
                    }
                }
            } else {
                print("Error")
                //completion(0.0, ("Breakfast error" as! Error))
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(total, nil)
        }
    }
    
    static func getLunchTotalForDay(day: DocumentReference, completion: @escaping (Double, Error?) -> Void) {
        var total = 0.0
        let group = DispatchGroup()
        
        group.enter()
        day.getDocument { (document, error) in
            if (document?.exists)! {
                if let lunchRef = document?.data()!["lunch"] {
                    let refArray = lunchRef as! [DocumentReference]
                    for ref in refArray {
                        group.enter()
                        ref.getDocument { (doc, error) in
                            if let doc = doc, doc.exists {
                                total = total + (doc.data()!["gallons_water"] as! Double)
                            } else {
                                print("Error")
                                //completion(0.0, ("Lunch error" as! Error))
                            }
                            group.leave()
                        }
                    }
                }
            } else {
                print("Error")
                //completion(0.0, ("Lunch error" as! Error))
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(total, nil)
        }
    }
    
    static func getDinnerTotalForDay(day: DocumentReference, completion: @escaping (Double, Error?) -> Void) {
        var total = 0.0
        let group = DispatchGroup()
        
        group.enter()
        day.getDocument { (document, error) in
            if (document?.exists)! {
                if let dinnerRef = document?.data()!["dinner"] {
                    let refArray = dinnerRef as! [DocumentReference]
                    for ref in refArray {
                        group.enter()
                        ref.getDocument { (doc, error) in
                            if let doc = doc, doc.exists {
                                total = total + (doc.data()!["gallons_water"] as! Double)
                            } else {
                                print("Error")
                                //completion(0.0, ("Dinner error" as! Error))
                            }
                            group.leave()
                        }
                    }
                }
            } else {
                print("Error")
                //completion(0.0, ("Dinner error" as! Error))
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(total, nil)
        }
    }
    
    static func getSnackTotalForDay(day: DocumentReference, completion: @escaping (Double, Error?) -> Void) {
        var total = 0.0
        let group = DispatchGroup()
        
        group.enter()
        day.getDocument { (document, error) in
            if (document?.exists)! {
                if let dinnerRef = document?.data()!["snacks"] {
                    let refArray = dinnerRef as! [DocumentReference]
                    for ref in refArray {
                        group.enter()
                        ref.getDocument { (doc, error) in
                            if let doc = doc, doc.exists {
                                total = total + (doc.data()!["gallons_water"] as! Double)
                            } else {
                                print("Error")
                                //completion(0.0, ("Snack error" as! Error))
                            }
                            group.leave()
                        }
                    }
                }
            } else {
                print("Error")
                //completion(0.0, ("Snack error" as! Error))
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(total, nil)
        }
    }
    
    static func getTotalForDay(day: DocumentReference, completion: @escaping (Double, Error?) -> Void) {
        getBreakfastTotalForDay(day: day) { (bTotal, error) in
            if let error = error {
                print (error)
            } else {
                getLunchTotalForDay(day: day) { (lTotal, error) in
                    if let error = error {
                        print (error)
                    } else {
                        getDinnerTotalForDay(day: day) { (dTotal, error) in
                            if let error = error {
                                print (error)
                            } else {
                                getSnackTotalForDay(day: day) { (sTotal, error) in
                                    if let error = error {
                                        print (error)
                                    } else {
                                        completion((bTotal + lTotal + dTotal + sTotal), nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
