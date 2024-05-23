//
//  EpisodesTableViewController.swift
//  Workshop05-0
//
//  Created by Michael Wybrow on 24/3/2024.
//

import UIKit

enum EpisodeListError: Error {
    case invalidShowURL
    case invalidServerResponse
}

struct ShowData: Codable {
    var name: String
    var embedded: EmbeddedShowData

    private enum CodingKeys: String, CodingKey {
        case name
        case embedded = "_embedded"
    }
}

struct EmbeddedShowData: Codable {
    var episodes: [EpisodeData]
}

class EpisodeData: Codable {
    var name: String
    var season: Int
    var number: Int
    // Summary might not exist for new episode, so optional
    var summary: String?
    var image: ImageData?
    
    // Don't want to be codable
    var uiImage: UIImage?
    var imageIsDownloading: Bool = false
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.season = try container.decode(Int.self, forKey: .season)
        self.number = try container.decode(Int.self, forKey: .number)
        self.image = try? container.decode(ImageData.self, forKey: .image)

        // Optional properties return nil rather than throwing an error.
        self.summary = try? container.decode(String.self, forKey: .summary)
        
        // Replace HTML tags in summary.
        self.summary = summary?.replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "</p>", with: "")
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case season
        case number
        case summary
        case image
    }

}

struct ImageData: Codable {
    var medium: String
    var original: String
}

class EpisodesTableViewController: UITableViewController {

    var episodes: [EpisodeData] = []
    var showId: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        navigationItem.title = "Loading TV Show..."
        
        guard let showId else {
            print("No show ID")
            return
        }
        
        guard let requestURL = URL(string: "https://api.tvmaze.com/shows/\(showId)?embed=episodes") else {
            print("Url not valid")
            return
        }
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: requestURL)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw EpisodeListError.invalidServerResponse
                }
                
                let decoder = JSONDecoder()
                let showData = try decoder.decode(ShowData.self, from: data)
                
                navigationItem.title = showData.name
                
                episodes = showData.embedded.episodes
                tableView.reloadData()
            }
            catch {
                print(error)
            }
        }

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "EpisodeCell", for: indexPath) as! EpisodeTableViewCell
        
        var episode = episodes[indexPath.row]
        cell.titleLabel.text = episode.name
        cell.infoLabel.text = "Season \(episode.season), episode \(episode.number)"
        cell.summaryLabel.text = episode.summary
        
        
        // Make sure the image is blank after cell reuse.
        cell.episodeImageView?.image = nil
        
        if let image = episode.uiImage {
            cell.episodeImageView?.image = image
        }
        else if episode.imageIsDownloading == false, let imageURL = episode.image?.medium {
            let requestURL = URL(string: imageURL)
            if let requestURL {
                Task {
                    print("Downloading image: " + imageURL)
                    episode.imageIsDownloading = true
                    do {
                        let (data, response) = try await URLSession.shared.data(from: requestURL)
                        guard let httpResponse = response as? HTTPURLResponse,
                              httpResponse.statusCode == 200 else {
                            episode.imageIsDownloading = false
                            throw EpisodeListError.invalidServerResponse
                        }
                        
                        if let image = UIImage(data: data) {
                            print("Image downloaded: " + imageURL)
                            episode.uiImage = image
                            tableView.reloadRows(at: [indexPath], with: .none)
                        }
                        else {
                            print("Image invalid: " + imageURL)
                            episode.imageIsDownloading = false
                        }
                    }
                    catch {
                        print(error.localizedDescription)
                    }
                    
                }
            }
            else {
                print("Error: URL not valid: " + imageURL)
            }
        }
        
        return cell

    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
