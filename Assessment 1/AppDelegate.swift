//
//  AppDelegate.swift
//  Assessment 1
//
//  Created by Cly Cly on 24/4/2024.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var databaseController: DatabaseProtocol?
    let coreDataController = CoreDataController.shared

    var persistentContainer: NSPersistentContainer

    override init() {
        persistentContainer = NSPersistentContainer(name: "A1-DataModel")
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        }
        super.init()
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.databaseController = coreDataController
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
}
