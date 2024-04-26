//
//  ViewController.swift
//  Assessment 1
//
//  Created by Cly Cly on 24/4/2024.
//

import UIKit

class Home: UIViewController {
    
    @IBOutlet weak var Leg: UIButton!
    @IBOutlet weak var Shoulder: UIButton!
    @IBOutlet weak var Back: UIButton!
    @IBOutlet weak var Arms: UIButton!
    @IBOutlet weak var Chest: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        var parameters: [String: String] = [:]
        
        switch sender {
        case Arms:
            parameters["muscle"] = "biceps"
        case Chest:
            parameters["muscle"] = "chest"
        case Leg:
            parameters["muscle"] = "legs"
        default:
            break
        }
        // 创建下一个视图控制器
        let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "MenuVC") as! MenuVC
        
        // 将按钮的标题传递到下一个视图控制器
        nextVC.buttonTitle = sender.currentTitle
        
        // 导航到下一个视图控制器
        self.navigationController?.pushViewController(nextVC, animated: true)
        // 调用 fetchExercises 函数
        fetchExercises(withParameters: parameters) { [weak self] result in
            
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    // 解析返回的数据
                    if let exercises = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        print(exercises)
                        // 在这里处理获取到的练习内容
                    } else {
                        print("Failed to parse exercises data")
                    }
                    


                case .failure(let error):
                    print("Error fetching exercises: \(error)")
                }
            }
        }
    }



        func fetchExercises(withParameters parameters: [String: String], completion: @escaping (Result<Data, Error>) -> Void) {
            let headers = [
                "X-RapidAPI-Key": "e4cd7ffbb8msh0f8e1ccd28eee69p127397jsnab7aa81736f6",
                "X-RapidAPI-Host": "exercisedb.p.rapidapi.com"
            ]

            // 构建 API 请求 URL
            var components = URLComponents(string: "https://exercisedb.p.rapidapi.com/exercises")!
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            
            // 构建请求
            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            // 发送请求
            let session = URLSession.shared
            let task = session.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.failure(NSError(domain: "com.example", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data returned"])))
                    }
                    return
                }
                completion(.success(data))
            }
            task.resume()
        }
    }
