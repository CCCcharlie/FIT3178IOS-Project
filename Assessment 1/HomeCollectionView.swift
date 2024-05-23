//
//  HomeCollectionView.swift
//  Assessment 1
//
//  Created by Cly Cly on 3/5/2024.
//

import UIKit

struct BodyPart: Decodable {
    let name: String
    let gifUrl: String
    // 可以添加其他属性
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

class HomeCollectionViewController: UICollectionViewController {
    
    var gifUrlCache: [String: String] = [:]
    var bodyPartsCache: [String: [BodyPart]] = [:]
    var bodyParts: [BodyPart] = []
    
    var groupedData: [String: [DummyExercise]] = [:]
    var uniqueBodyParts: [String] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化 collection view
//        fetchBodyParts()
        
        setupDummyData()
        collectionView.setCollectionViewLayout(createWorkshop2Layout3(), animated: false)

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
        
        let bodyPart = bodyParts[indexPath.section]
//
//        cell.titleLabel.text = bodyPart.name
        
        let bodyPartName = uniqueBodyParts[indexPath.section]  // 获取正确的 bodyPart 名称
        cell.titleLabel.text = bodyPartName  // 设置单元格标题为 bodyPart 名称
        
        
        
        // 设置图片（如果有的话）
//        if !bodyPart.gifUrl.isEmpty {
//            if let gifUrl = URL(string: bodyPart.gifUrl) {
//                // 使用异步方式加载图像
//                URLSession.shared.dataTask(with: gifUrl) { (data, response, error) in
//                    // 检查是否有错误和数据
//                    guard let data = data, let image = UIImage(data: data) else {
//                        // 加载失败时，设置默认图像或执行其他处理
//                        DispatchQueue.main.async {
//                            // 设置默认图像
//                             cell.imageView?.image = UIImage(named: "Image")
//                        }
//                        return
//                    }
//                    // 加载成功时，更新单元格的图像
//                    DispatchQueue.main.async {
//                        cell.imageView?.image = image
//                    }
//                }.resume()
//            }
//        }
        if let exercises = groupedData[bodyPartName] {
            let exercise = exercises[indexPath.item]  // 获取当前分区中对应的 DummyExercise
            
            // 设置图像
            if let gifUrl = URL(string: exercise.gifUrl) {
                URLSession.shared.dataTask(with: gifUrl) { (data, response, error) in
                    guard let data = data, let image = UIImage(data: data) else {
                        DispatchQueue.main.async {
                            cell.imageView?.image = UIImage(named: "Image")  // 设置默认图像
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        cell.imageView?.image = image
                    }
                }.resume()
            }
            
            else {
                
                cell.imageView?.image = UIImage(named: "Image") // 设置默认图像
                
                // 如果 gifUrl 为空，则设置默认图像或执行其他处理
                // cell.imageView?.image = UIImage(named: "placeholder_image")
            }
        }
        return cell
    }

//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let selectedBodyPart = bodyParts[indexPath.item]
//        
//        
//        // 使用 setupDummyData 生成的数据
//        let dummyExercises = setupDummyData()
//        
////        fetchExercises(for: selectedBodyPart.name) { result in
////            switch result {
////            case .success(let exercises):
////                let nextViewController = SubmenuCollectionViewController()
////                nextViewController.exercises = exercises
////                print("sending exercises \(exercises)")
////
////                DispatchQueue.main.async {
////                    self.navigationController?.pushViewController(nextViewController, animated: true)
////                }
////            case .failure(let error):
////                print("Error fetching exercises for \(selectedBodyPart.name): \(error)")
////            }
////        }
//        
//        performSegue(withIdentifier: "showExercises", sender: selectedBodyPart)
//         
//        
//    }
    
//    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        <#code#>
//    }

    func fetchBodyParts() {
        
        // 检查是否有缓存数据
        if let cachedBodyParts = bodyPartsCache["all"] {
            
            print("using cache ")

            // 直接使用缓存数据
            self.bodyParts = cachedBodyParts
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }

            return

        }
        print("cachedBodyParts bodyPartsCache \(bodyPartsCache)")

        let url = URL(string: "https://exercisedb.p.rapidapi.com/exercises/bodyPartList")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = [
            "X-RapidAPI-Key": "8e858fa2bfmshd4cce323c6fad71p1df64cjsnca80adf9b4dd",
            "X-RapidAPI-Host": "exercisedb.p.rapidapi.com"
        ]
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                print("Error fetching body parts: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data returned from API")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let bodyPartNames = try decoder.decode([String].self, from: data)
                
                // Create a dispatch group to track when all requests are completed
                let group = DispatchGroup()
                
                for bodyPartName in bodyPartNames {
                    group.enter() // Enter the dispatch group for each request
                    
                    self?.fetchExercises(for: bodyPartName) { result in
                        defer {
                            group.leave() // Leave the dispatch group when the request is completed
                        }
                        switch result {
                        case .success(let exercises):
                            print("Exercises for \(bodyPartName): \(exercises)")
                            
                            // Create a new BodyPart object with name and gifUrl
                            let bodyPart = BodyPart(name: bodyPartName, gifUrl: exercises.first?.gifUrl ?? "")
                            
                            // Append the new BodyPart to bodyParts array
                            self?.bodyParts.append(bodyPart)
                            
                        case .failure(let error):
                            print("Error fetching exercises for \(bodyPartName): \(error)")
                        }
                    }
                }
                
                // Notify when all requests are completed
                group.notify(queue: .main) {
                    
                    // All requests are completed
                    // Cache the body parts data
                    self?.bodyPartsCache["all"] = self?.bodyParts
                    // Reload UI or handle exercises data here
                    self?.collectionView.reloadData()
                }
                
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
        
        task.resume()
        
    }

    func fetchExercises(for bodyPartName: String, completion: @escaping (Result<[BodyPart], Error>) -> Void) {
        // Check if GIF URL is already cached
        if let cachedUrl = gifUrlCache[bodyPartName] {
            // Return cached URL
            let cachedBodyPart = BodyPart(name: bodyPartName, gifUrl: cachedUrl)
            completion(.success([cachedBodyPart]))
            print("Using cached data for \(bodyPartName)")
            return
        }

        // API request
        // Construct API request URL for a specific body part
        let url = URL(string: "https://exercisedb.p.rapidapi.com/exercises/bodyPart/\(bodyPartName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = [
            "X-RapidAPI-Key": "8e858fa2bfmshd4cce323c6fad71p1df64cjsnca80adf9b4dd",
            "X-RapidAPI-Host": "exercisedb.p.rapidapi.com"
        ]

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                // Request failed, attempt to use cached data
                if let cachedUrl = self.gifUrlCache[bodyPartName] {
                    // Return cached URL
                    let cachedBodyPart = BodyPart(name: bodyPartName, gifUrl: cachedUrl)
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
            let decoder = JSONDecoder()
            let dummyExercises = try decoder.decode([DummyExercise].self, from: dummyData)
            
            // 将 DummyExercise 转换为 BodyPart
            self.bodyParts = dummyExercises.map { BodyPart(name: $0.bodyPart, gifUrl: $0.gifUrl) }
//             uniqueBodyParts = Set(bodyParts.map { $0.name })

            
             groupedData = dummyExercises.reduce(into: [String: [DummyExercise]]()) { result, exercise in
                let bodyPart = exercise.bodyPart
                result[bodyPart, default: []].append(exercise)
            }
            // 刷新 collection view
            self.collectionView.reloadData()
            
            // 使用 reduce(into:_:) 方法将 DummyExercise 数据按照 bodyPart 分组

            
            
            uniqueBodyParts = groupedData.keys.sorted() // 保证顺序一致

            // Flatten the dictionary into an array of DummyExercise
//            let groupedExercises = groupedData.values.flatMap { $0 }
//            print("uniqueBodyParts: \(uniqueBodyParts)")

            return dummyExercises

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
    }

}
