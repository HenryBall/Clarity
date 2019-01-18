//
//  AppDelegate.swift
//  Clarity
//
//  Created by Robert on 5/14/18.
//  Copyright © 2018 Clarity. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    let s = UIStoryboard(name: "Main", bundle: nil)
    let window = UIWindow(frame: UIScreen.main.bounds)
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        let homeViewController = s.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        let loginViewController = s.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
      
        let navigationController: UINavigationController = s.instantiateInitialViewController() as! UINavigationController
        UIApplication.shared.statusBarStyle = .lightContent
        
        if let userID = UserDefaults.standard.string(forKey: "user_id") {
            userRef = db.collection("users").document(userID)
            userRef.getDocument { (doc, error) in
                if let doc = doc, doc.exists {
                    if (doc.data()!["water_goal"] as? Double) != nil {
                        if (!GIDSignIn.sharedInstance().hasAuthInKeychain()){
                            navigationController.viewControllers = [homeViewController]
                        }
                    } else {
                        navigationController.viewControllers = [loginViewController]
                    }
                }
            }
        }
        self.window.rootViewController = navigationController
        self.window.makeKeyAndVisible()
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.tintColor = UIColor(red: 75/255, green: 150/255, blue: 255/255, alpha: 216/255)
        navigationBarAppearace.barTintColor = UIColor(red: 75/255, green: 150/255, blue: 255/255, alpha: 216/255)
        
        return true
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication: sourceApplication,
                                                 annotation: annotation)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        if let error = error {
            print(error)
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error)
                return
            }
            
            let db = Firestore.firestore()
            let document = db.collection("users").document(GIDSignIn.sharedInstance().currentUser.userID)
            document.setData(["email": user?.email, "name": user?.displayName], options: SetOptions.merge())
            UserDefaults.standard.set(GIDSignIn.sharedInstance().currentUser.userID, forKey: "user_id")
            
            document.getDocument { (document, error) in
                if let document = document, document.exists {
                    let homeVC = self.s.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
                    let settingsVC = self.s.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
                    
                    //Check if the user has a water limit saved. If so, just show homeVC, if not, show settings
                    if (document.data()?["water_goal"]) != nil {
                        let nv = self.window.rootViewController as! UINavigationController
                        nv.viewControllers = [homeVC]
                    } else {
                        let nv = self.window.rootViewController as! UINavigationController
                        nv.viewControllers = [homeVC, settingsVC]
                    }
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription) \(String(describing: document.data()?.count))")
                } else {
                    print("Document does not exist")
                }
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

