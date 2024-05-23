//
//  File.swift
//  Assessment 1
//
//  Created by Cly Cly on 10/5/2024.
//

import UIKit

class SubmenuCollectionViewController: UICollectionViewController {
    var exercises: [DummyExercise] = []

    // Custom initializer to pass exercises
//    init(exercises: [DummyExercise]) {
//        self.exercises = exercises
//        let layout = UICollectionViewFlowLayout()
//        super.init(collectionViewLayout: layout)
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //setupDummyData()
        print("Exercises in viewDidLoad: \(exercises)") // 确认初始化后的 exercises 不为空
        collectionView.setCollectionViewLayout(createWorkshop2Layout3(), animated: false)

    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Exercises in sub \(exercises)") // 确认在 collectionView 数据源方法中 exercises 不为空
        return exercises.count
    }

//    // Method to configure exercises after initialization
//    func configure(exercises: [DummyExercise]) {
//        self.exercises = exercises
//    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubmenuCell", for: indexPath) as! SubmenuCell

        let exercise = exercises[indexPath.item]
        cell.titleLabel.text = exercise.name
        
        if !exercise.gifUrl.isEmpty {
            if let gifUrl = URL(string: exercise.gifUrl) {
                URLSession.shared.dataTask(with: gifUrl) { (data, response, error) in
                    guard let data = data, let image = UIImage(data: data) else {
                        DispatchQueue.main.async {
                            cell.imageView.image = UIImage(named: "placeholder_image") // Placeholder image
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        cell.imageView.image = image
                    }
                }.resume()
            }
        } else {
            cell.imageView.image = UIImage(named: "placeholder_image") // Placeholder image
        }
        
        return cell
    }
    func createWorkshop2Layout3() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 1.0, bottom: 0, trailing: 1.0)
            
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .fractionalWidth(0.6))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
      
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging

        // Section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let headerLayout = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [headerLayout]

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    func setupDummyData() -> [DummyExercise] {
        let dummyData = """
        [
            {
                "bodyPart": "Legs",
                "equipment": "Dumbbell",
                "gifUrl": "https://www.runnersworld.com/beginner/a20780292/the-six-best-exercises-for-new-runners/",
                "id": "1",
                "name": "Squat",
                "target": "Quadriceps",
                "secondaryMuscles": ["Hamstrings", "Glutes"],
                "instructions": ["Stand with your feet shoulder-width apart.", "Lower your body as if you were sitting back into a chair."]
            },
            {
                "bodyPart": "Chest",
                "equipment": "Barbell",
                "gifUrl": "https://uddingstonphysiotherapy.co.uk/wp-content/uploads/bb-plugin/cache/uddingstron-physiotherapy-gym-img-9-portrait-1e856601c1a25da61670f43d981990f1-3j0rgliwn8uf.jpg",
                "id": "2",
                "name": "Bench Press",
                "target": "Pectoralis Major",
                "secondaryMuscles": ["Triceps", "Deltoids"],
                "instructions": ["Lie on a bench with your feet flat on the floor.", "Grip the barbell slightly wider than shoulder-width apart."]
            },
            {
                "bodyPart": "Chest",
                "equipment": "Barbell",
                "gifUrl": "https://dummyimage.com/200x200/000/fff&text=Exercise+2",
                "id": "2",
                "name": "Bench Press",
                "target": "Pectoralis Major",
                "secondaryMuscles": ["Triceps", "Deltoids"],
                "instructions": ["Lie on a bench with your feet flat on the floor.", "Grip the barbell slightly wider than shoulder-width apart."]
            },
            {
                "bodyPart": "Back",
                "equipment": "Pull-up Bar",
                "gifUrl": "https://dummyimage.com/200x200/000/fff&text=Exercise+3",
                "id": "3",
                "name": "Pull-up",
                "target": "Latissimus Dorsi",
                "secondaryMuscles": ["Biceps", "Forearms"],
                "instructions": ["Hang from a pull-up bar with your palms facing away from you.", "Pull yourself up until your chin is above the bar."]
            },
            {
                "bodyPart": "Arms",
                "equipment": "Dumbbell",
                "gifUrl": "https://dummyimage.com/200x200/000/fff&text=Exercise+4",
                "id": "4",
                "name": "Bicep Curl",
                "target": "Biceps",
                "secondaryMuscles": ["Forearms"],
                "instructions": ["Stand up straight with a dumbbell in each hand.", "Keep your elbows close to your torso and curl the weights while contracting your biceps."]
            }
        ]
        """.data(using: .utf8)!
        
        do {
            let decoder = JSONDecoder()
            let dummyExercises = try decoder.decode([DummyExercise].self, from: dummyData)
            
            self.exercises = dummyExercises

            // 刷新 collection view
            self.collectionView.reloadData()
            
            // 使用 reduce(into:_:) 方法将 DummyExercise 数据按照 bodyPart 分组
            let groupedData = dummyExercises.reduce(into: [String: [DummyExercise]]()) { result, exercise in
                let bodyPart = exercise.bodyPart
                result[bodyPart, default: []].append(exercise)
            }
            
            // Flatten the dictionary into an array of DummyExercise
            let groupedExercises = groupedData.values.flatMap { $0 }
            print("groupedExercises: \(groupedExercises)")

            return groupedExercises

        } catch {
            print("Error decoding JSON: \(error)")
            return []
        }
    }
}
