//
//  ViewController.swift
//  SharePlayDemo
//
//  Created by ENFINY INNOVATIONS on 10/26/21.
//

import UIKit


class ViewController: UIViewController {
    
    var movies: [MovieData]?
    
    lazy var tableView: UITableView = {
       let tv = UITableView()
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Video list"
        
        view.addSubview(tableView)

        tableView.frame = view.frame
        
        getData()
        
        // Do any additional setup after loading the view.
        

    }
    
    
    func getData() {
        movies = load("Movies.json") as? [MovieData]
        tableView.reloadData()
    }
    
     func load(_ filename: String) -> Decodable {
        let data: Data
        guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
            fatalError("Couldn't find \(filename) in main bundle.")
        }
        
        do {
            data = try Data(contentsOf: file)
        } catch {
            fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([MovieData].self, from: data)
        } catch {
            fatalError("could not parse")
        }
    }


}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies?.count ?? 0
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = movies?[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = VideoPlayerVC(movie: movies![indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }


}
