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
    
    func toDummyExercise() -> DummyExercise {
        let gifUrlString = self.gifUrl ?? ""
        let secondaryMusclesString = self.secondaryMuscles ?? ""
        let instructionsString = self.instructions ?? ""
        
        return DummyExercise(bodyPart: self.bodyPart ?? "",
                             equipment: self.equipment ?? "",
                             gifUrl: gifUrlString,
                             id: self.objectID.uriRepresentation().absoluteString,
                             name: self.name ?? "",
                             target: self.target ?? "",
                             secondaryMuscles: [secondaryMusclesString], // 将字符串放入一个字符串数组中
                             instructions: [instructionsString]) // 将字符串放入一个字符串数组中
    }
    
    

}
extension User {

    @objc(addFavouriteMoviesObject:)
    @NSManaged public func addToExercise(_ value: Exercise)

    @objc(removeFavouriteMoviesObject:)
    @NSManaged public func removeFromExercise(_ value: Exercise)

    @objc(addFavouriteMovies:)
    @NSManaged public func addToExercise(_ values: NSSet)

    @objc(removeFavouriteMovies:)
    @NSManaged public func removeFromExercise(_ values: NSSet)

}

extension Exercise : Identifiable {

}
