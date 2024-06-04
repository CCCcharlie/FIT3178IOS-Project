//
//  CoreDataController.swift
//  Assessment 1
//
//  Created by Cly Cly on 24/5/2024.
//

import UIKit
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    static let shared = CoreDataController()

    
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
    var allExercisesFetchedResultsController: NSFetchedResultsController<Exercise>?

    override init() {
        persistentContainer = NSPersistentContainer(name: "A1-DataModel")
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        super.init()
    }
    
    func convertToExercise(_ dummyExercise: DummyExercise) -> Exercise? {
        let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: persistentContainer.viewContext) as! Exercise
        exercise.name = dummyExercise.name
        exercise.bodyPart = dummyExercise.bodyPart
        exercise.equipment = dummyExercise.equipment
        exercise.gifUrl = dummyExercise.gifUrl
        exercise.target = dummyExercise.target
        exercise.secondaryMuscles = dummyExercise.secondaryMuscles.joined(separator: ", ")
        exercise.instructions = dummyExercise.instructions.joined(separator: "\n")
        
        // Save the context after converting to Exercise
        saveContext()
        cleanup()
        
        return exercise
    }
    func storeDummyExercises(_ dummyExercises: [DummyExercise]) {
        
//        clearAllExercises()
        
        for dummyExercise in dummyExercises {
            let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: persistentContainer.viewContext) as! Exercise
            exercise.name = dummyExercise.name
            exercise.bodyPart = dummyExercise.bodyPart
            exercise.equipment = dummyExercise.equipment
            exercise.gifUrl = dummyExercise.gifUrl
            exercise.target = dummyExercise.target
            exercise.secondaryMuscles = dummyExercise.secondaryMuscles.joined(separator: ", ")
            exercise.instructions = dummyExercise.instructions.joined(separator: "\n")

            
            
            // Save the context after each exercise is added
            saveContext()
            cleanup()
            print("Total exercises after adding: \(fetchAllExercises().count)")

            
        }
    }
    func clearAllExercises() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Exercise")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentContainer.viewContext.execute(deleteRequest)
            try persistentContainer.viewContext.save()
        } catch {
            print("Failed to delete all exercises: \(error)")
        }
    }
    
    
    func cleanup() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save Core Data context: \(error)")
            }
        }
    }

    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == .exercise || listener.listenerType == .all {
            listener.onExerciseChange(change: .update, exercises: fetchAllExercises())
        }
        if listener.listenerType == .user || listener.listenerType == .all {
            listener.onUserChange(change: .update, users: fetchAllUsers())
        }
    }

    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }

    func addExercise(name: String, bodyPart: String, equipment: String, gifUrl: String, target: String, secondaryMuscles: String, instructions: String, customby: User?) -> Exercise {
        let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: persistentContainer.viewContext) as! Exercise
        exercise.name = name
        exercise.bodyPart = bodyPart
        exercise.equipment = equipment
        exercise.gifUrl = gifUrl
        exercise.target = target
        exercise.secondaryMuscles = secondaryMuscles
        exercise.instructions = instructions
        exercise.customby = customby

        saveContext()
        return exercise
    }

    func deleteExercise(exercise: Exercise) {
        persistentContainer.viewContext.delete(exercise)
        saveContext()
    }

    func fetchAllExercises() -> [Exercise] {
        
        
        if allExercisesFetchedResultsController == nil {
            let request: NSFetchRequest<Exercise> = Exercise.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]

            allExercisesFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            allExercisesFetchedResultsController?.delegate = self

            do {
                try allExercisesFetchedResultsController?.performFetch()
            } catch {
                print("Fetch request failed: \(error)")
            }
        }
//        clearAllExercises()

        return allExercisesFetchedResultsController?.fetchedObjects ?? []
    }

    func fetchAllUsers() -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        do {
            return try persistentContainer.viewContext.fetch(request)
        } catch {
            print("Fetch request failed: \(error)")
            return []
        }
    }

    private func saveContext() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }

    // MARK: - NSFetchedResultsControllerDelegate
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == allExercisesFetchedResultsController {
            listeners.invoke { listener in
                if listener.listenerType == .exercise || listener.listenerType == .all {
                    listener.onExerciseChange(change: .update, exercises: fetchAllExercises())
                }
            }
        }
    }
    
    func createDefaultExercises() {
        let _ = addExercise(name: "Push-up", bodyPart: "Chest", equipment: "None", gifUrl: "push_up.gif", target: "Pectorals", secondaryMuscles: "Triceps", instructions: "Place your hands on the floor. Raise up onto your toes so that all of your body weight is on your hands and your feet. Bend your elbows and lower your chest down to the floor. Then, push off the floor and extend your arms back to the starting position.", customby: nil)
        let _ = addExercise(name: "Pull-up", bodyPart: "Back", equipment: "Pull-up Bar", gifUrl: "pull_up.gif", target: "Lats", secondaryMuscles: "Biceps", instructions: "Grab the pull-up bar with your palms down (shoulder-width grip). Hang to the pull-up bar with your arms extended. Pull yourself up by pulling your elbows down to the floor. Go all the way up until your chin passes the bar. Lower yourself until your arms are straight.", customby: nil)
        let _ = addExercise(name: "Squat", bodyPart: "Legs", equipment: "None", gifUrl: "squat.gif", target: "Quadriceps", secondaryMuscles: "Glutes", instructions: "Stand with feet a little wider than shoulder-width apart, hips stacked over knees, and knees over ankles. Extend your arms out straight so they are parallel with the ground, palms facing down. Initiate the movement by inhaling, and unlocking the hips, slightly bringing them back. Keep sending hips backward as the knees begin to bend. While the butt starts to stick out, make sure the chest and shoulders stay upright, and the back stays straight. Keep the head facing forward with eyes straight ahead for a neutral spine. Engage core and, with bodyweight in the heels, explode back up to standing, driving through heels. Repeat.", customby: nil)
        let _ = addExercise(name: "Deadlift", bodyPart: "Legs", equipment: "Barbell", gifUrl: "deadlift.gif", target: "Hamstrings", secondaryMuscles: "Glutes", instructions: "Stand with your mid-foot under the barbell. Bend over and grab the bar with a shoulder-width grip. Bend your knees until your shins touch the bar. Lift your chest up and straighten your lower back. Take a big breath, hold it, and stand up with the weight. Hold the weight for a second at the top with locked hips and knees. Return the weight to the floor by moving your hips back while bending your legs. Reset and repeat.", customby: nil)
        cleanup()
    }
}
