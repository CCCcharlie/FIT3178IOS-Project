//
//  Exercise+CoreDataProperties.swift
//  Assessment 1
//
//  Created by Cly Cly on 24/5/2024.
//
//

import Foundation
import CoreData


extension Exercise {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise")
    }

    @NSManaged public var bodyPart: String?
    @NSManaged public var equipment: String?
    @NSManaged public var gifUrl: String?
    @NSManaged public var target: String?
    @NSManaged public var name: String?
    @NSManaged public var secondaryMuscles: String?
    @NSManaged public var instructions: String?
    @NSManaged public var customby: User?

}

extension Exercise : Identifiable {

}
