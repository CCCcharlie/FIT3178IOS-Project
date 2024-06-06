//
//  HomeCollectionView.swift
//  Assessment 1
//
//  Created by Cly Cly on 3/5/2024.
//

import UIKit
import CoreData


struct BodyPart: Decodable {
    let bodyPart: String
    let equipment: String
    let gifUrl: String
    let id: String
    let name: String
    let target: String
    let secondaryMuscles: [String]
    let instructions: [String]
}


struct DummyExercise: Decodable {
    let bodyPart: String
    let equipment: String
    let gifUrl: String
    let id: String
    let name: String
    let target: String
    let secondaryMuscles: [String]
    let instructions: [String]
}


class HomeCollectionViewController: UICollectionViewController, AddCreateExerciseDelegate, DatabaseListener {
    @IBOutlet var TapGesture:
    UITapGestureRecognizer!
    var coreDataController: CoreDataController!
    var managedObjectContext: NSManagedObjectContext?

    var databaseController: DatabaseProtocol?
    var exercises: [Exercise] = []
    var listenerType: ListenerType = .exercise
    
    var gifUrlCache: [String: String] = [:]
    var bodyPartsCache: [String: [BodyPart]] = [:]
    var bodyParts: [BodyPart] = []
    
    var groupedData: [String: [DummyExercise]] = [:]
    var uniqueBodyParts: [String] = []

    func didAddExercise(_ exercise: Exercise) {
        // 将 Exercise 实例转换为 DummyExercise 实例
        let dummyExercise = exercise.toDummyExercise()
        
        // 获取 bodyPart
        let bodyPart = dummyExercise.bodyPart
        
        // 检查 groupedData 中是否已经存在相应的键
        if groupedData[bodyPart] != nil {
            // 如果存在，则将 dummyExercise 添加到现有的数组中
            groupedData[bodyPart]?.append(dummyExercise)
        } else {
            // 如果不存在，则创建一个新的数组，并将 dummyExercise 添加到其中
            groupedData[bodyPart] = [dummyExercise]
        }
        
        // 刷新 collectionView，以便显示新的数据
        self.collectionView.reloadData()
    }
    // MARK: - DatabaseListener

    lazy var appDelegate = {
        guard let appDelegate =  UIApplication.shared.delegate as?  AppDelegate else {
            fatalError("No AppDelegate")
        }
        return appDelegate
    }()
    
    
    
    @IBAction func simpleNotificationAction(_ sender: Any) {
        guard appDelegate.notificationsEnabled else {
            print("Notifications not enabled")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to work out "
        content.body = "Pick the excerise for today..."
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: true)
        
        let request = UNNotificationRequest(identifier: AppDelegate.NOTIFICATION_IDENTIFIER, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
        print("Notification scheduled.")
    }
    
    
    func onExerciseChange(change: DatabaseChange, exercises: [Exercise]) {
        self.exercises = exercises
         print("Number of exercises in CoreData: \(exercises.count)") // 打印最新的 exercise 数量
         collectionView.reloadData()
    }

    func onUserChange(change: DatabaseChange, users: [User]) {
        // Handle user changes if needed
    }

    // MARK: - Navigation
    


    @IBAction func Addbutton(_ sender: UIButton) {
        self.shouldPerformSegue(withIdentifier: "c", sender: nil)
        navigationController?.popViewController(animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let coreDataController = coreDataController else {
            fatalError("CoreDataController is not initialized")
        }

        managedObjectContext = coreDataController.persistentContainer.viewContext

        // Load dummy data
        _ = setupDummyData()

        collectionView.setCollectionViewLayout(createWorkshop2Layout3(), animated: false)

        let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextButtonTapped))
        self.navigationItem.rightBarButtonItem = nextButton

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        collectionView.addGestureRecognizer(doubleTapGesture)
    }
    
    @objc func nextButtonTapped() {
        // 获取 Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // 获取新的 ViewController
        if let createExerciseVC = storyboard.instantiateViewController(withIdentifier: "CreateExerciseViewController") as? CreateExerciseViewController {
            // 设置 delegate
            createExerciseVC.addCreateExerciseDelegate = self
            createExerciseVC.databaseController = self.databaseController
            // 跳转到新的 ViewController
            self.navigationController?.pushViewController(createExerciseVC, animated: true)
        }
    }



    // 实现 UICollectionViewDataSource 协议方法
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let bodyPart = uniqueBodyParts[section]
        print("sending exercises \(groupedData)")
        return groupedData[bodyPart]?.count ?? 0
        
    }
    
    // 修改 cellForItemAt 方法
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExerciseCell", for: indexPath) as! ExerciseCell
        
        
        let bodyPartName = uniqueBodyParts[indexPath.section]  // 获取正确的 bodyPart 名称
        

        if let exercises = groupedData[bodyPartName] {
            
            
            let exercise = exercises[indexPath.item]  // 获取当前分区中对应的 DummyExercise
            cell.titleLabel.text = exercise.name

            // 设置图像
            let gifUrlString = exercise.gifUrl
            print("Loading image from URL: \(gifUrlString)")  // 添加日志
            if let gifUrl = URL(string: gifUrlString) {
                print("Created URL: \(gifUrl)")  // 添加日志
                if gifUrl.isFileURL {
                    let fileUrl = gifUrl
                    do {
                        let imageData = try Data(contentsOf: fileUrl)
                        if let image = UIImage(data: imageData) {
                            cell.imageView?.image = image
                        } else {
                            print("Failed to create image from data")  // 添加日志
                            cell.imageView?.image = UIImage(named: "Image")  // 设置默认图像
                        }
                    } catch {
                        print("Error loading image data from \(fileUrl): \(error)")  // 添加日志
                        cell.imageView?.image = UIImage(named: "Image")  // 设置默认图像
                    }
                } else {
                    URLSession.shared.dataTask(with: gifUrl) { (data, response, error) in
                        guard let data = data, let image = UIImage(data: data) else {
                            DispatchQueue.main.async {
                                print("Failed to load image from URL: \(gifUrl), error: \(error?.localizedDescription ?? "Unknown error")")  // 添加日志
                                cell.imageView?.image = UIImage(named: "Image")
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            cell.imageView?.image = image
                        }
                    }.resume()
                }
            } else {
                print("Failed to create URL from string: \(gifUrlString)")  // 添加日志
                cell.imageView?.image = UIImage(named: "Image")  // 设置默认图像
            } 
//            else {
//                cell.imageView?.image = UIImage(named: "Image")
//            }
        }
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerView", for: indexPath) as? HeaderCollectionReusableView {
            // 获取正确的 bodyPart 名称
            let bodyPartName = uniqueBodyParts[indexPath.section]
            sectionHeader.labelTextView.text = bodyPartName
            return sectionHeader
        }
        return UICollectionReusableView()
    }

//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        <#code#>
//    }
    // IBAction for double tap gesture
    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let point = gestureRecognizer.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: point) {
            let bodyPartName = uniqueBodyParts[indexPath.section]
            if var exercises = groupedData[bodyPartName] {
                let dummyExerciseToDelete = exercises[indexPath.item]
                
                // 首先将 DummyExercise 转换为 Exercise
                guard let exerciseToDelete = CoreDataController.shared.convertToExercise(dummyExerciseToDelete) else {
                    print("Failed to convert DummyExercise to Exercise.")
                    return
                }
                
                // 调用 deleteExercise 删除 Exercise
                CoreDataController.shared.deleteExercise(exercise: exerciseToDelete)
                
                exercises.remove(at: indexPath.item)
                groupedData[bodyPartName] = exercises
                collectionView.deleteItems(at: [indexPath])
            }
        }
        self.collectionView.reloadData()

    }




    func fetchBodyParts(completion: @escaping () -> Void) {
        // 检查是否有缓存数据
        if let cachedBodyParts = bodyPartsCache["all"] {
            print("Using cache")
            // 直接使用缓存数据
            self.bodyParts = cachedBodyParts
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            completion()
            return
        }
        
        let url = URL(string: "https://exercisedb.p.rapidapi.com/exercises/bodyPartList")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = [
            "X-RapidAPI-Key": "0e5564552cmshab1f7bb2d0093a4p15e5e2jsn1f3237cf9987",
            "X-RapidAPI-Host": "exercisedb.p.rapidapi.com"
        ]
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                print("Error fetching body parts: \(error)")
                completion()
                return
            }
            
            guard let data = data else {
                print("No data returned from API")
                completion()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let bodyPartNames = try decoder.decode([String].self, from: data)
                
                // Create a dispatch group to track when all requests are completed
                let group = DispatchGroup()
                var allExercises: [BodyPart] = [] // 临时数组保存所有 BodyPart 对象
                
                for bodyPartName in bodyPartNames {
                    group.enter() // Enter the dispatch group for each request
                    
                    self?.fetchExercises(for: bodyPartName) { result in
                        defer {
                            group.leave() // Leave the dispatch group when the request is completed
                        }
                        switch result {
                        case .success(let exercises):
                            print("Exercises for \(bodyPartName): \(exercises)")
                            // Add fetched body parts to the temporary array
                            allExercises.append(contentsOf: exercises)
                            
                        case .failure(let error):
                            print("Error fetching exercises for \(bodyPartName): \(error)")
                        }
                    }
                }
                
                // Notify when all requests are completed
                group.notify(queue: .main) {
                    // All requests are completed
                    // Cache the body parts data
                    self?.bodyParts = allExercises // 将临时数组赋值给 self.bodyParts
                    self?.bodyPartsCache["all"] = allExercises
                    
                    // Group the fetched data by bodyPart
                    self?.groupedData = allExercises.reduce(into: [String: [DummyExercise]]()) { result, bodyPart in
                        // Convert BodyPart to DummyExercise
                        let dummyExercise = DummyExercise(
                            bodyPart: bodyPart.bodyPart,
                            equipment: bodyPart.equipment,
                            gifUrl: bodyPart.gifUrl,
                            id: bodyPart.id,
                            name: bodyPart.name,
                            target: bodyPart.target,
                            secondaryMuscles: bodyPart.secondaryMuscles,
                            instructions: bodyPart.instructions
                        )
                        result[bodyPart.bodyPart, default: []].append(dummyExercise)
                    }
                    
                    // Reload collection view
                    self?.collectionView.reloadData()
                    completion() // 调用 completion handler
                }
                
            } catch {
                print("Error decoding JSON: \(error)")
                completion()
            }
        }
        
        task.resume()
    }


    func fetchExercises(for bodyPartName: String, completion: @escaping (Result<[BodyPart], Error>) -> Void) {
        // Check if GIF URL is already cached
        if let cachedUrl = gifUrlCache[bodyPartName] {
            // Return cached URL
            let cachedBodyPart = BodyPart(bodyPart: bodyPartName, equipment: "", gifUrl: cachedUrl, id: "", name: "", target: "", secondaryMuscles: [], instructions: [])
            completion(.success([cachedBodyPart]))
            print("Using cached data for \(bodyPartName)")
            return
        }

        // API request
        // Construct API request URL for a specific body part
        let url = URL(string: "https://exercisedb.p.rapidapi.com/exercises/bodyPart/\(bodyPartName)?limit=2")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = [
            "X-RapidAPI-Key": "0e5564552cmshab1f7bb2d0093a4p15e5e2jsn1f3237cf9987",
            "X-RapidAPI-Host": "exercisedb.p.rapidapi.com"
        ]
        request.timeoutInterval = 30 // timeout gap

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                // Request failed, attempt to use cached data
                if let cachedUrl = self.gifUrlCache[bodyPartName] {
                    // Return cached URL
                    let cachedBodyPart = BodyPart(bodyPart: bodyPartName, equipment: "", gifUrl: cachedUrl, id: "", name: "", target: "", secondaryMuscles: [], instructions: [])
                    completion(.success([cachedBodyPart]))
                    print("Using cached data for \(bodyPartName) due to error: \(error)")
                } else {
                    // No cached data available, return error
                    completion(.failure(error))
                }
                return
            }
            
            // Handle API response
            guard let data = data else {
                let error = NSError(domain: "com.example", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
                completion(.failure(error))
                return
            }
            do {
                let decoder = JSONDecoder()
                // Assuming that the response contains an array of BodyPart objects
                let exercises = try decoder.decode([BodyPart].self, from: data)

                // Cache GIF URL for each body part
                for exercise in exercises {
                    self.gifUrlCache[exercise.name] = exercise.gifUrl
                }
                
                completion(.success(exercises))

            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
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
//            let decoder = JSONDecoder()
//            let dummyExercises = try decoder.decode([DummyExercise].self, from: dummyData)
//            
//            coreDataController.storeDummyExercises(dummyExercises)
            
            
            // Retrieve exercises saved in Core Data
            
            let savedExercises = coreDataController.fetchAllExercises()
            
            
            guard !savedExercises.isEmpty else {
                // Handle the case when there are no saved exercises
//                print("No saved exercises, using dummy data")
//                
//
//
//    
//                 groupedData = dummyExercises.reduce(into: [String: [DummyExercise]]()) { result, exercise in
//                    let bodyPart = exercise.bodyPart
//                    result[bodyPart, default: []].append(exercise)
//                }
//                // 刷新 collection view
//                self.collectionView.reloadData()
//                
//                // 使用 reduce(into:_:) 方法将 DummyExercise 数据按照 bodyPart 分组
//
//                
//                
//                uniqueBodyParts = groupedData.keys.sorted() // 保证顺序一致
                
                
                // Handle the case when there are no saved exercises
                print("No saved exercises, using dummy data")
                
                // Retrieve dummy exercises from fetchBodyParts()
                fetchBodyParts {
                    // Convert fetched body parts to dummy exercises
                    let dummyExercises = self.bodyParts.map { bodyPart in
                        return DummyExercise(
                            bodyPart: bodyPart.bodyPart,
                            equipment: bodyPart.equipment,
                            gifUrl: bodyPart.gifUrl,
                            id: bodyPart.id, // Assuming DummyExercise has an 'id' property
                            name: bodyPart.name,
                            target: bodyPart.target,
                            secondaryMuscles: bodyPart.secondaryMuscles,
                            instructions: bodyPart.instructions
                        )
                    }
                    
                    // Store dummy exercises in Core Data
                    self.coreDataController.storeDummyExercises(dummyExercises)
                    
                    // Group the fetched data by bodyPart
                    self.groupedData = dummyExercises.reduce(into: [String: [DummyExercise]]()) { result, exercise in
                        result[exercise.bodyPart, default: []].append(exercise)
                    }
                    
                    // Reload collection view
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                    
                    // Update uniqueBodyParts
                    self.uniqueBodyParts = self.groupedData.keys.sorted()
                }
                
                // Return an empty array or some placeholder if needed
                return []
            }

            // Do something with savedExercises if needed
            
//            self.bodyParts = savedExercises.compactMap { exercise in
//                guard let name = exercise.bodyPart, let gifUrl = exercise.gifUrl else {
//                    return nil
//                }
//                return BodyPart(name: name, gifUrl: gifUrl)
//            }
            

            // have data saved


            groupedData = savedExercises.reduce(into: [String: [DummyExercise]]()) { result, exercise in
                guard let bodyPart = exercise.bodyPart else { return }
                
                // Create a new DummyExercise object with Exercise properties
                let dummyExercise = DummyExercise(
                    bodyPart: bodyPart,
                    equipment: exercise.equipment ?? "",
                    gifUrl: exercise.gifUrl ?? "",
                    id: "", // You might need to handle this depending on your DummyExercise model
                    name: exercise.name ?? "",
                    target: exercise.target ?? "",
                    secondaryMuscles: exercise.secondaryMuscles?.components(separatedBy: ", ") ?? [],
                    instructions: exercise.instructions?.components(separatedBy: "\n") ?? []
                )
                
                // Append the DummyExercise to the result dictionary
                result[bodyPart, default: []].append(dummyExercise)
            
        
            }
            self.collectionView.reloadData()
        
            
            
            uniqueBodyParts = groupedData.keys.sorted() // 保证顺序一致


            return []

        } catch {
            print("Error decoding JSON: \(error)")
            return []
        }
    }
    
    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return uniqueBodyParts.count

    }

    func createWorkshop2Layout4() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(2/5), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 1.0, bottom: 0, trailing: 1.0)
      
        let item2Size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(3/5), heightDimension: .fractionalHeight(1.0))
        let item2 = NSCollectionLayoutItem(layoutSize: item2Size)
      
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.6))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item2])
      
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered

        // Section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let headerLayout = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [headerLayout]

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    func createBasicListLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
      
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalWidth(1.0))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
      
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging

        // Section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let headerLayout = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [headerLayout]

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }    
    func createHeaderLayout() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        let headerLayout = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        return headerLayout
    }
    func createTiledLayoutSection() -> NSCollectionLayoutSection {
        // Tiled layout.
        //  * Group is three posters, side-by-side.
        //  * Group is 1 x screen width, and height is 1/2 x screen width (poster height)
        //  * Poster width is 1/3 x group width, with height as 1 x group width
        //  * This makes item dimensions 2:3
        //  * contentInsets puts a 1 pixel margin around each poster.
        let posterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1))
        let posterLayout = NSCollectionLayoutItem(layoutSize: posterSize)
        posterLayout.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(1/2))
        let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [posterLayout])
        
        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.boundarySupplementaryItems = [createHeaderLayout()]
        //layoutSection.orthogonalScrollingBehavior = .continuous
        return layoutSection
    }
    
    func createSideScrollingLayoutSection() -> NSCollectionLayoutSection {
        // Horizontal side-scrolling layout.
        //  * Group is two posters side-by-side.
        //  * Group is 4/5 x screen width, and height is 4/5 * 1.5 (2:3) /2 (only one poster high, not 2) x screen width.
        //  * Poster width is 0.5 x group width, with height as 1 x group width
        //  * This makes item dimensions 2:3
        //  * contentInsets puts a 1 pixel margin around each poster.
        //  * orthogonalScrollingBehavior property allows side-scrolling.
        let posterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2), heightDimension: .fractionalHeight(1))
        let posterLayout = NSCollectionLayoutItem(layoutSize: posterSize)
        posterLayout.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(4/5), heightDimension: .fractionalWidth(4/5 * 0.75))
        let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [posterLayout])
        
        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.orthogonalScrollingBehavior = .groupPaging
        //layoutSection.orthogonalScrollingBehavior = .groupPagingCentered
        layoutSection.boundarySupplementaryItems = [createHeaderLayout()]
        
        return layoutSection
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showExercises" {
            if let destination = segue.destination as? EpisodesTableViewController, let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
                // 使用存储在 dummyExercises 属性中的所有数据
                let allExercises = setupDummyData()
                
                let selectedBodyPart = uniqueBodyParts[selectedIndexPath.section]
                
                // 根据 selectedBodyPart 筛选所需的 dummy exercises
                //                let exercisesForSelectedBodyPart = allExercises.filter { $0.bodyPart == selectedBodyPart.name }
                if let exercisesForSelectedBodyPart = groupedData[selectedBodyPart]{
                    destination.exercises = exercisesForSelectedBodyPart
                }
            }
            
        }
        else if segue.identifier == "c" {
            if let createExerciseVC = segue.destination as? CreateExerciseViewController {
                createExerciseVC.addCreateExerciseDelegate = self
            }
        }

            
        
    }

}
