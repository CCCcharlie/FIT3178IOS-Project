//
//  User+CoreDataProperties.swift
//  Assessment 1
//
//  Created by Cly Cly on 24/5/2024.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var name: String?
    @NSManaged public var customexcercise: Exercise?

}

extension User : Identifiable {

}
