//
//  AppDelegate.swift
//  Assessment 1
//
//  Created by Cly Cly on 24/4/2024.
//

import UIKit
import CoreData
import UserNotifications


@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var databaseController: DatabaseProtocol?
    let coreDataController = CoreDataController.shared
    var notificationsEnabled = false
    static let NOTIFICATION_IDENTIFIER = "edu.monash.fit3178.week10"
    static let CATEGORY_IDENTIFIER = "edu.monash.fit3178.week10.category"
    
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        
        return [.banner]
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                self.notificationsEnabled = true
                self.scheduleNotification()
            } else {
                self.notificationsEnabled = false
            }
        }
        
        self.databaseController = coreDataController
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func scheduleNotification() {
        guard notificationsEnabled else {
            print("Notifications not enabled")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to work out"
        content.body = "Pick the exercise for today..."
        content.categoryIdentifier = AppDelegate.CATEGORY_IDENTIFIER

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 21600, repeats: true)  // 3秒后触发

        let request = UNNotificationRequest(identifier: AppDelegate.NOTIFICATION_IDENTIFIER, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled.")
            }
        }
    }


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
}
