//
//  DatabaseProtocol.swift
//  Assessment 1
//
//  Created by Cly Cly on 24/5/2024.
//

import Foundation

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case exercise
    case user
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType { get set }
    func onExerciseChange(change: DatabaseChange, exercises: [Exercise])
    func onUserChange(change: DatabaseChange, users: [User])
}

protocol DatabaseProtocol: AnyObject {
    func cleanup()
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    func addExercise(name: String, bodyPart: String, equipment: String, gifUrl: String, target: String, secondaryMuscles: String, instructions: String, customby: User?) -> Exercise
    func deleteExercise(exercise: Exercise)
}
